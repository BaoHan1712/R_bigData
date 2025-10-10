import pandas as pd


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
