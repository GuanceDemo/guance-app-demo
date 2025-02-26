from flask import Flask, request, jsonify, render_template, url_for
from ddtrace import tracer, patch
#from flask_cors import CORS

# 启用 Flask 的 ddtrace 自动监控
patch(flask=True)

app = Flask(__name__)

# @app.before_request
# def extract_trace_info():
#     """从请求头中提取 trace_id 和 span_id，并统一存储到 request 对象中"""
#     # 提取 Datadog 的 trace-id 和 parent-id
#     datadog_trace_id = request.headers.get("x-datadog-trace-id")
#     datadog_span_id = request.headers.get("x-datadog-parent-id")

#     # 提取 W3C Trace Context 的 traceparent
#     traceparent = request.headers.get("traceparent")
#     if traceparent:
#         parts = traceparent.split('-')
#         if len(parts) >= 3:
#             # 提取 trace-id 和 parent-id
#             w3c_trace_id = parts[1]
#             w3c_span_id = parts[2]
#         else:
#             # 如果 traceparent 格式不正确，可以记录日志或忽略
#             app.logger.warning(f"Invalid traceparent header: {traceparent}")
#             w3c_trace_id = None
#             w3c_span_id = None
#     else:
#         w3c_trace_id = None
#         w3c_span_id = None

#     # 统一 trace_id 和 span_id
#     # 优先级：W3C Trace Context > Datadog
#     request.trace_id = w3c_trace_id if w3c_trace_id else datadog_trace_id
#     request.span_id = w3c_span_id if w3c_span_id else datadog_span_id

# @app.after_request
# def attach_trace_info(response):
#     """将 trace_id 和 span_id 附加到响应头"""
#     if hasattr(request, "trace_id") and request.trace_id:
#         # 同时支持 Datadog 和 W3C Trace Context
#         response.headers["trace_id"] = request.trace_id

#     if hasattr(request, "span_id") and request.span_id:
#         response.headers["span_id"] = request.span_id

#     return response

@app.after_request
def after_request(response):
    # 获取当前的 trace span
    span = tracer.current_span()
    if span:
        response.headers["span_id"] = str(span.span_id)
        response.headers["trace_id"] = str(span.trace_id)
    return response

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
