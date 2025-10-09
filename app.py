from flask import Flask, render_template, request
import requests

app = Flask(__name__)

R_API = "http://127.0.0.1:8000/predict"

@app.route('/', methods=['GET', 'POST'])
def index():
    predicted = None
    hours = None
    if request.method == 'POST':
        hours = float(request.form['hours'])
        response = requests.get(R_API, params={'hours': hours})
        if response.status_code == 200:
            predicted = response.json()['predicted_score']
    return render_template('index.html', hours=hours, predicted=predicted)

if __name__ == '__main__':
    app.run(debug=True, port=5000)
