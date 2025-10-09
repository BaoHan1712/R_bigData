import pandas as pd

# Tạo dữ liệu giả lập về điểm sinh viên
data = {
    "Student": [f"SV{i}" for i in range(1, 21)],
    "Hours_Studied": [2, 3, 4, 5, 1, 6, 3, 4, 7, 8, 5, 6, 9, 10, 8, 7, 4, 3, 2, 1],
    "Score": [35, 45, 50, 55, 25, 65, 48, 52, 70, 80, 60, 68, 85, 88, 78, 75, 54, 42, 30, 20]
}

df = pd.DataFrame(data)
df.to_csv("student_scores.csv", index=False)

print("✅ Đã tạo file student_scores.csv")
print(df.head())
