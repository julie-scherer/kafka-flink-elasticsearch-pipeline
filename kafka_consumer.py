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
# SOURCE: https://github.com/apache/flink-playgrounds/blob/4aa9a341bbf49e51809bc9cfcf0e946b2accd8ac/pyflink-walkthrough/payment_msg_proccessing.py
from pyflink.datastream import StreamExecutionEnvironment, TimeCharacteristic
from pyflink.table import StreamTableEnvironment, DataTypes, EnvironmentSettings
from pyflink.table.expressions import call, col
from pyflink.table.udf import udf


provinces = ("Alberta",
             "British Columbia",
             "Manitoba",
             "New Brunswick",
             "Newfoundland and Labrador",
             "Northwest Territories",
             "Nova Scotia",
             "Nunavut",
             "Ontario",
             "Prince Edward Island",
             "Quebec",
             "Saskatchewan",
             "Yukon")

@udf(input_types=[DataTypes.STRING()], result_type=DataTypes.STRING())
def province_id_to_name(id):
    return provinces[id]


def log_processing():
    env = StreamExecutionEnvironment.get_execution_environment()

    iceberg_flink_runtime_jar = "/opt/iceberg/lib/iceberg-flink-runtime-1.16-1.2.1.jar"
    env.add_jars(f"file://{iceberg_flink_runtime_jar}")
    
    t_env = StreamTableEnvironment.create(stream_execution_environment=env)
    t_env.get_config().get_configuration().set_boolean("python.fn-execution.memory.managed", True)

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

    create_iceberg_catalog_ddl = """
            CREATE CATALOG iceberg_sink with (
               'type'='iceberg',
               'catalog-type'='hadoop',
               'warehouse'='s3a://my-bucket/my-warehouse',
               'catalog-impl'='org.apache.iceberg.aws.glue.GlueCatalog', 
               'io-impl'='org.apache.iceberg.aws.s3.S3FileIO'
            )
    """
    create_iceberg_table_ddl = """
            CREATE TABLE iceberg_sink.my_table (
                province VARCHAR PRIMARY KEY,
                pay_amount DOUBLE
            ) with (
                'connector' = 'iceberg',
                'catalog' = 'iceberg_sink',
                'database' = 'default',
                'table-name' = 'my_table',

                'sink.bulk-flush.max-size' = '42mb',
                'sink.bulk-flush.max-actions' = '32',
                'sink.bulk-flush.interval' = '1000',
                'sink.bulk-flush.backoff.delay' = '1000',
                'format' = 'parquet'
            )
    """


    t_env.execute_sql(create_kafka_source_ddl)
    t_env.execute_sql(create_iceberg_catalog_ddl)
    t_env.register_function('province_id_to_name', province_id_to_name)

    t_env.from_path("payment_msg") \
        .select(call('province_id_to_name', col('provinceId')).alias("province"), col('payAmount')) \
        .group_by(col('province')) \
        .select(col('province'), call('sum', col('payAmount').alias("pay_amount"))) \
        .execute_insert("my_table")


if __name__ == '__main__':
    log_processing()
