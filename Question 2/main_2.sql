-- **Question 2**

-- How would you structure a database schema to store address information for customers,
-- considering that the addresses of some customers may change over time? Give pros and
-- cons for each option?

-- **Answer**
1. Customer Address Schema

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50)
);

CREATE TABLE addresses (
    address_id INT PRIMARY KEY,
    customer_id INT,
    street_address VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    valid_from DATE,
    valid_to DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


*Ưu điểm:

- Lưu trữ được toàn bộ lịch sử địa chỉ của khách hàng.
- Có thể truy vấn địa chỉ của khách hàng tại bất kỳ thời điểm nào.
- Đáp ứng yêu cầu về việc địa chỉ có thể thay đổi theo thời gian.

*Nhược điểm:

- Cấu trúc phức tạp, đòi hỏi kỹ năng quản lý và truy vấn cao hơn.
- Cần nhiều không gian lưu trữ hơn do lưu trữ lịch sử.
- Truy vấn địa chỉ hiện tại có thể chậm hơn nếu không được tối ưu hóa.

----------------------------------------------------------------------------------------------------------------------------

2. Optimized Customer Address Schema

CREATE TABLE customers (
    customer_id BIGINT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE address_types (
    address_type_id SMALLINT PRIMARY KEY,
    type_name VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE countries (
    country_id SMALLINT PRIMARY KEY,
    country_name VARCHAR(50) UNIQUE NOT NULL,
    country_code CHAR(2) UNIQUE NOT NULL
);

CREATE TABLE addresses (
    address_id BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    address_type_id SMALLINT NOT NULL,
    street_address VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country_id SMALLINT NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP,
    is_current BOOLEAN GENERATED ALWAYS AS (valid_to IS NULL) STORED,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (address_type_id) REFERENCES address_types(address_type_id),
    FOREIGN KEY (country_id) REFERENCES countries(country_id)
);

CREATE INDEX idx_addresses_customer_current ON addresses (customer_id, is_current);
CREATE INDEX idx_addresses_valid_period ON addresses (valid_from, valid_to);

CREATE TABLE address_changes (
    change_id BIGINT PRIMARY KEY,
    address_id BIGINT NOT NULL,
    changed_at TIMESTAMP NOT NULL,
    changed_by VARCHAR(50),
    change_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(address_id)
);

Tóm tắt cấu trúc:

- Sử dụng kiểu dữ liệu phù hợp:
    + BIGINT cho các khóa chính trong bảng lớn (customers, addresses) để hỗ trợ số lượng bản ghi lớn.
    + SMALLINT cho các bảng tham chiếu nhỏ (address_types, countries) để tiết kiệm không gian.
- Bảng tham chiếu:
    + address_types: Cho phép phân loại địa chỉ (ví dụ: nhà riêng, công ty).
    + countries: Chuẩn hóa thông tin quốc gia, giúp tránh lỗi nhập liệu và tiết kiệm không gian.
- Cột được tạo tự động:
    + is_current: Được tạo tự động dựa trên giá trị của valid_to, giúp truy vấn địa chỉ hiện tại nhanh hơn.
- Indexing:
    + idx_addresses_customer_current: Tối ưu cho truy vấn địa chỉ hiện tại của khách hàng.
    + idx_addresses_valid_period: Hỗ trợ truy vấn hiệu quả dựa trên khoảng thời gian.
- Bảng address_changes:
    + Lưu trữ lịch sử thay đổi địa chỉ, hỗ trợ kiểm toán và phân tích.
- Timestamps:
    + created_at và updated_at trong bảng customers để theo dõi thời gian tạo và cập nhật thông tin khách hàng.
- Ràng buộc và tính nhất quán:
    + Sử dụng FOREIGN KEY để đảm bảo tính toàn vẹn dữ liệu.
    + Sử dụng UNIQUE constraint cho các trường như country_name và country_code.

Ưu điểm của schema này:

- Hiệu suất cao: Indexing và cột được tạo tự động giúp tối ưu hóa truy vấn.
- Tiết kiệm không gian: Sử dụng bảng tham chiếu và kiểu dữ liệu phù hợp.
- Tính linh hoạt: Có thể dễ dàng mở rộng để thêm các loại địa chỉ mới.
- Tính nhất quán: Ràng buộc và chuẩn hóa dữ liệu giúp duy trì tính nhất quán.
- Hỗ trợ phân tích: Lưu trữ lịch sử thay đổi và thời gian hiệu lực.

Nhược điểm:

- Phức tạp: Đòi hỏi kỹ năng quản lý và truy vấn.
- Overhead cho các thao tác insert/update: Do có nhiều bảng và ràng buộc.