from flask import Flask, request, jsonify, render_template, url_for
from ddtrace import tracer
#from flask_cors import CORS

app = Flask(__name__)

@app.route('/api/login', methods=['POST'])
def login():
    username = request.json.get('username')
    password = request.json.get('password')

    if username == 'guance' and password == 'admin':
        result = {
            'success': True
        }
        return jsonify(result), 200
    else:
        return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/api/user', methods=['GET'])
def get_user():
    host = request.host
    avatar_url = url_for('static', filename='images/demo-icon.png')
    user = {
        'username': 'GuanceDemo',
        'email': 'guance@example.com',
        'avatar': f'http://{host}{avatar_url}'
    }
    return jsonify(user), 200

@app.route('/connect', methods=['GET'])
def connect():
    result = {
        'success': True
    }
    return jsonify(result), 200

# HTML 页面渲染，此处为移动端 WebView 展示使用
@app.route('/')
def index():
    name = 'GC_WebView'
    return render_template('index.html', name=name)
    
@app.route('/import_helper')
def import_helper():
    name = 'GC_Demo_Import_Heler'
    return render_template('import_helper.html', name=name)

if __name__ == '__main__':
    #局域网设置
    app.run(host='0.0.0.0', port=8000)
