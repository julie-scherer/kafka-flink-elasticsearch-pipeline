################################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
################################################################################
import os
import shutil
import site


from pyflink.datastream import StreamExecutionEnvironment, TimeCharacteristic
from pyflink.table import StreamTableEnvironment, DataTypes, EnvironmentSettings
from pyflink.table.expressions import call, col
from pyflink.table.udf import udf


provinces = ("Beijing", "Shanghai", "Hangzhou", "Shenzhen", "Jiangxi", "Chongqing", "Xizang")


@udf(input_types=[DataTypes.STRING()], result_type=DataTypes.STRING())
def province_id_to_name(id):
    return provinces[id]


def copy_all_hadoop_jars_to_pyflink():
    if not os.getenv("HADOOP_HOME"):
        raise Exception("The HADOOP_HOME env var must be set and point to a valid Hadoop installation")

    jar_files = []

    def find_pyflink_lib_dir():
        for dir in site.getsitepackages():
            package_dir = os.path.join(dir, "pyflink", "lib")
            if os.path.exists(package_dir):
                return package_dir
        return None

    for root, _, files in os.walk(os.getenv("HADOOP_HOME")):
        for file in files:
            if file.endswith(".jar"):
                jar_files.append(os.path.join(root, file))

    pyflink_lib_dir = find_pyflink_lib_dir()

    num_jar_files = len(jar_files)
    print(f"Copying {num_jar_files} Hadoop jar files to pyflink's lib directory at {pyflink_lib_dir}")
    for jar in jar_files:
        shutil.copy(jar, pyflink_lib_dir)


def create_kafka_source(t_env):
    create_kafka_source_ddl = """
            CREATE TABLE payment_msg(
                createTime VARCHAR,
                orderId BIGINT,
                payAmount DOUBLE,
                payPlatform INT,
                provinceId INT
            ) WITH (
              'connector' = 'kafka',
              'topic' = 'payment_msg',
              'properties.bootstrap.servers' = 'kafka:9092',
              'properties.group.id' = 'test_3',
              'scan.startup.mode' = 'latest-offset',
              'format' = 'json'
            )
        """
    t_env.execute_sql(create_kafka_source_ddl)
    return t_env

def create_es_sink(t_env):
    create_es_sink_ddl = """
            CREATE TABLE es_sink(
                province VARCHAR PRIMARY KEY,
                pay_amount DOUBLE
            ) with (
                'connector' = 'elasticsearch-7',
                'hosts' = 'http://elasticsearch:9200',
                'index' = 'platform_pay_amount_1',
                'document-id.key-delimiter' = '$',
                'sink.bulk-flush.max-size' = '42mb',
                'sink.bulk-flush.max-actions' = '32',
                'sink.bulk-flush.interval' = '1000',
                'sink.bulk-flush.backoff.delay' = '1000',
                'format' = 'json'
            )
        """
    t_env.execute_sql(create_es_sink_ddl)
    return t_env

def create_iceberg_catalog(t_env):
    catalog_name = "iceberg_sink"
    # https://iceberg.apache.org/docs/latest/flink/#hive-catalog
    create_iceberg_catalog_ddl = f"""    
        CREATE CATALOG {catalog_name} WITH (
                'type'='iceberg',
                'catalog-type'='hive',
                'uri'='thrift://localhost:9083',
                'clients'='5',
                'property-version'='1',
                'warehouse'='hdfs://nn:8020/warehouse/path'
            );
        """
    t_env.execute_sql(create_iceberg_catalog_ddl)
    return t_env

def create_iceberg_table(t_env):
    catalog_name = "iceberg_sink"
    table_name = "my_table"
    create_iceberg_table_ddl = f"""
            CREATE TABLE {catalog_name}.{table_name} (
                province VARCHAR PRIMARY KEY,
                pay_amount DOUBLE
            ) with (
                'connector' = 'iceberg',
                'catalog' = '{catalog_name}',
                'database' = 'default',
                'table-name' = '{table_name}',

                'sink.bulk-flush.max-size' = '42mb',
                'sink.bulk-flush.max-actions' = '32',
                'sink.bulk-flush.interval' = '1000',
                'sink.bulk-flush.backoff.delay' = '1000',
                'format' = 'parquet'
            )
        """
    t_env.execute_sql(create_iceberg_table_ddl)
    return t_env

def process_data(t_env):
    t_env.register_function('province_id_to_name', province_id_to_name)

    t_env.from_path("payment_msg") \
        .select(call('province_id_to_name', col('provinceId')).alias("province"), col('payAmount')) \
        .group_by(col('province')) \
        .select(col('province'), call('sum', col('payAmount').alias("pay_amount"))) \
        .execute_insert("es_sink")
        # .execute_insert("my_table")


def log_processing():
    # copy_all_hadoop_jars_to_pyflink()

    env = StreamExecutionEnvironment.get_execution_environment()
    t_env = StreamTableEnvironment.create(stream_execution_environment=env)
    t_env.get_config().get_configuration().set_boolean("python.fn-execution.memory.managed", True)

    t_env = create_kafka_source(t_env)
    t_env = create_es_sink(t_env)

    process_data(t_env)


if __name__ == '__main__':
    log_processing()
