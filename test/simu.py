import pandas as pd
import numpy as np
import os # Thêm thư viện os để kiểm tra file có tồn tại không

# --- PHẦN 1: TẠO 9000 DÒNG DỮ LIỆU MỚI (Giữ nguyên code của bạn) ---

# Số lượng dòng dữ liệu mới cần tạo
num_records_new = 9000

# Tạo dữ liệu mô phỏng cho từng cột
data = {
    'school': np.random.choice(['GP', 'MS'], size=num_records_new, p=[0.7, 0.3]),
    'sex': np.random.choice(['F', 'M'], size=num_records_new),
    'age': np.random.randint(15, 20, size=num_records_new),
    'address': np.random.choice(['U', 'R'], size=num_records_new, p=[0.75, 0.25]),
    'famsize': np.random.choice(['GT3', 'LE3'], size=num_records_new, p=[0.7, 0.3]),
    'Pstatus': np.random.choice(['T', 'A'], size=num_records_new, p=[0.9, 0.1]),
    'Medu': np.random.randint(0, 5, size=num_records_new),
    'Fedu': np.random.randint(0, 5, size=num_records_new),
    'Mjob': np.random.choice(['teacher', 'health', 'services', 'at_home', 'other'], size=num_records_new),
    'Fjob': np.random.choice(['teacher', 'health', 'services', 'at_home', 'other'], size=num_records_new),
    'reason': np.random.choice(['course', 'reputation', 'home', 'other'], size=num_records_new),
    'guardian': np.random.choice(['mother', 'father', 'other'], size=num_records_new, p=[0.6, 0.3, 0.1]),
    'traveltime': np.random.randint(1, 5, size=num_records_new),
    'studytime': np.random.randint(1, 5, size=num_records_new),
    'failures': np.random.choice([0, 1, 2, 3], size=num_records_new, p=[0.8, 0.1, 0.05, 0.05]),
    'schoolsup': np.random.choice(['yes', 'no'], size=num_records_new, p=[0.1, 0.9]),
    'famsup': np.random.choice(['yes', 'no'], size=num_records_new, p=[0.6, 0.4]),
    'paid': np.random.choice(['yes', 'no'], size=num_records_new, p=[0.45, 0.55]),
    'activities': np.random.choice(['yes', 'no'], size=num_records_new, p=[0.5, 0.5]),
    'nursery': np.random.choice(['yes', 'no'], size=num_records_new, p=[0.8, 0.2]),
    'higher': np.random.choice(['yes', 'no'], size=num_records_new, p=[0.95, 0.05]),
    'internet': np.random.choice(['yes', 'no'], size=num_records_new, p=[0.85, 0.15]),
    'romantic': np.random.choice(['yes', 'no'], size=num_records_new, p=[0.35, 0.65]),
    'famrel': np.random.randint(1, 6, size=num_records_new),
    'freetime': np.random.randint(1, 6, size=num_records_new),
    'goout': np.random.randint(1, 6, size=num_records_new),
    'Dalc': np.random.randint(1, 6, size=num_records_new),
    'health': np.random.randint(1, 6, size=num_records_new),
    'absences': np.random.randint(0, 25, size=num_records_new),
    'G1': np.random.randint(4, 20, size=num_records_new),
}

# Tạo DataFrame mới từ dữ liệu đã mô phỏng
df_new = pd.DataFrame(data)

# Mô phỏng Walc, G2, G3
df_new['Walc'] = df_new['Dalc'] + np.random.randint(0, 2, size=num_records_new)
df_new['Walc'] = df_new['Walc'].clip(1, 5)
df_new['G2'] = df_new['G1'] + np.random.randint(-3, 4, size=num_records_new)
df_new['G3'] = df_new['G2'] + np.random.randint(-3, 4, size=num_records_new)
df_new[['G1', 'G2', 'G3']] = df_new[['G1', 'G2', 'G3']].clip(0, 20)

# Sắp xếp lại các cột theo đúng thứ tự
column_order = [
    'school','sex','age','address','famsize','Pstatus','Medu','Fedu','Mjob','Fjob',
    'reason','guardian','traveltime','studytime','failures','schoolsup','famsup',
    'paid','activities','nursery','higher','internet','romantic','famrel','freetime',
    'goout','Dalc','Walc','health','absences','G1','G2','G3'
]
df_new = df_new[column_order]

# --- PHẦN 2: GHI DỮ LIỆU RA FILE CSV ---
csv_file_path = 'student_performance.csv'

if os.path.exists(csv_file_path):
    print(f"Đang đọc file có sẵn: '{csv_file_path}'...")
    df_existing = pd.read_csv(csv_file_path)
    print(f"File cũ có {len(df_existing)} dòng, thêm {num_records_new} dòng mới...")
    df_combined = pd.concat([df_existing, df_new], ignore_index=True)
else:
    print(f"Không tìm thấy '{csv_file_path}', tạo file mới với {num_records_new} dòng.")
    df_combined = df_new

# Ghi file CSV
print("Đang ghi dữ liệu vào file CSV...")
df_combined.to_csv(csv_file_path, index=False, encoding='utf-8-sig')

print(f"\n✅ Hoàn thành! File '{csv_file_path}' hiện có {len(df_combined)} dòng.")
print("\nXem trước 5 dòng cuối:")
print(df_combined.tail())