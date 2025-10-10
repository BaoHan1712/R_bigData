import pandas as pd

# # URL file gốc từ GitHub (bản UCI Student Performance)
# url_mat = "https://raw.githubusercontent.com/arunk13/MSDA-Assignments/master/IS607Fall2015/Assignment3/student-mat.csv"
# url_por = "https://raw.githubusercontent.com/arunk13/MSDA-Assignments/master/IS607Fall2015/Assignment3/student-por.csv"

# # Đọc dữ liệu
# df_mat = pd.read_csv(url_mat, sep=';')
# df_por = pd.read_csv(url_por, sep=';')

# # Gộp lại thành 1 dataset chung
# df_all = pd.concat([df_mat, df_por], axis=0).reset_index(drop=True)

# # Lưu ra file CSV tại cùng thư mục đang chạy script
# df_all.to_csv("student_performance.csv", index=False)

# print("✅ Đã lưu file: student_performance.csv")
# print("Số dòng:", len(df_all))
# print("Các cột:", list(df_all.columns))


df = pd.read_csv("student_performance.csv")

# Các cột cần giữ
cols_to_keep = [
    'studytime', 'failures',
    'internet',
    'G1', 'G2', 'G3'
]

df_clean = df[cols_to_keep]
df_clean.to_csv("student_performance_clean.csv", index=False)

print("✅ Đã lưu file student_performance_clean.csv")
print("Số dòng:", len(df_clean))
print("Số cột:", len(df_clean.columns))
print("Các cột:", list(df_clean.columns))
