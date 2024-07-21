# Đây là một chương trình Python thực hiện quy trình ETL (Extract, Transform, Load) để tải dữ liệu từ một file JSON vào cơ sở dữ liệu PostgreSQL.
# Chương trình bao gồm các bước sau:
# 1. Kết nối đến cơ sở dữ liệu PostgreSQL.
# 2. Tạo bảng "employees" nếu chưa tồn tại.
# 3. Đọc và chuyển đổi dữ liệu từ file JSON.
# 4. Tải dữ liệu đã chuyển đổi vào bảng "employees".
# 5. Đóng kết nối đến cơ sở dữ liệu sau khi hoàn thành.

import json
import os
import psycopg2
from psycopg2 import sql, extras
from datetime import datetime
import logging

# Cấu hình logging
logging.basicConfig(level=logging.INFO)

# Hàm kết nối đến PostgreSQL
def connect_to_db():
    try:
        conn = psycopg2.connect(
            host=os.getenv("DB_HOST"),
            database=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD")
        )
        return conn
    except (Exception, psycopg2.Error) as error:
        logging.error("Lỗi khi kết nối đến PostgreSQL: %s", error)
        return None

# Hàm tạo bảng employees
def create_table(conn):
    try:
        with conn.cursor() as cursor:
            create_table_query = '''
                CREATE TABLE IF NOT EXISTS employees (
                    id INTEGER PRIMARY KEY,
                    name TEXT,
                    department TEXT,
                    salary INTEGER,
                    join_date DATE
                )
            '''
            cursor.execute(create_table_query)
            conn.commit()
            logging.info("Bảng employees đã được tạo thành công")
    except (Exception, psycopg2.Error) as error:
        logging.error("Lỗi khi tạo bảng: %s", error)

# Hàm đọc và chuyển đổi dữ liệu từ file JSON
def extract_transform_data(file_path):
    try:
        with open(file_path, 'r') as file:
            data = json.load(file)
    except (Exception, json.JSONDecodeError) as e:
        logging.error("Lỗi khi đọc file JSON: %s", e)
        return []
    transformed_data = []
    for employee in data:
        try:
            transformed_employee = {
                'id': employee['id'],
                'name': employee['name'],
                'department': employee['department'],
                'salary': employee['salary'],
                'join_date': datetime.strptime(employee['join_date'], '%Y-%m-%d').date()
            }
            transformed_data.append(transformed_employee)
        except KeyError as e:
            logging.warning("Lỗi: Thiếu trường dữ liệu %s cho nhân viên %s", e, employee.get('id', 'Unknown'))
        except ValueError as e:
            logging.warning("Lỗi: Định dạng ngày không hợp lệ cho nhân viên %s", employee.get('id', 'Unknown'))
    return transformed_data

# Hàm tải dữ liệu vào PostgreSQL
def load_data(conn, data):
    if not data:
        logging.warning("Không có dữ liệu để tải vào")
        return
    try:
        with conn.cursor() as cursor:
            insert_query = '''
                INSERT INTO employees (id, name, department, salary, join_date)
                VALUES %s
                ON CONFLICT (id) DO UPDATE SET
                    name = EXCLUDED.name,
                    department = EXCLUDED.department,
                    salary = EXCLUDED.salary,
                    join_date = EXCLUDED.join_date
            '''
            extras.execute_values(
                cursor, insert_query, 
                [(emp['id'], emp['name'], emp['department'], emp['salary'], emp['join_date']) for emp in data]
            )
            conn.commit()
            logging.info("Dữ liệu đã được tải thành công vào bảng employees")
    except (Exception, psycopg2.Error) as error:
        logging.error("Lỗi khi tải dữ liệu: %s", error)

# Hàm main để chạy quá trình ETL
def main():
    conn = connect_to_db()
    if conn is None:
        return
    try:
        create_table(conn)
        data = extract_transform_data('employees.json')
        load_data(conn, data)
    finally:
        if conn:
            conn.close()
            logging.info("Kết nối PostgreSQL đã đóng")

if __name__ == "__main__":
    main()