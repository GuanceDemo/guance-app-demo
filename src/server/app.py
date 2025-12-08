from flask import Flask, request, jsonify, render_template, url_for
from ddtrace import tracer, patch
#from flask_cors import CORS

# Enable ddtrace auto-instrumentation for Flask
patch(flask=True)

# Server version information
SERVER_VERSION = "1.0.1"
BUILD_DATE = "2025-11-21"

app = Flask(__name__)

# @app.before_request
# def extract_trace_info():
#     """Extract trace_id and span_id from request headers and store them in the request object"""
#     # Extract Datadog's trace-id and parent-id
#     datadog_trace_id = request.headers.get("x-datadog-trace-id")
#     datadog_span_id = request.headers.get("x-datadog-parent-id")

#     # Extract W3C Trace Context's traceparent
#     traceparent = request.headers.get("traceparent")
#     if traceparent:
#         parts = traceparent.split('-')
#         if len(parts) >= 3:
#             # Extract trace-id and parent-id
#             w3c_trace_id = parts[1]
#             w3c_span_id = parts[2]
#         else:
#             # If traceparent format is incorrect, you can log or ignore
#             app.logger.warning(f"Invalid traceparent header: {traceparent}")
#             w3c_trace_id = None
#             w3c_span_id = None
#     else:
#         w3c_trace_id = None
#         w3c_span_id = None

#     # Unified trace_id and span_id
#     # Priority: W3C Trace Context > Datadog
#     request.trace_id = w3c_trace_id if w3c_trace_id else datadog_trace_id
#     request.span_id = w3c_span_id if w3c_span_id else datadog_span_id

# @app.after_request
# def attach_trace_info(response):
#     """Attach trace_id and span_id to response headers"""
#     if hasattr(request, "trace_id") and request.trace_id:
#         # Support both Datadog and W3C Trace Context
#         response.headers["trace_id"] = request.trace_id

#     if hasattr(request, "span_id") and request.span_id:
#         response.headers["span_id"] = request.span_id

#     return response

@app.after_request
def after_request(response):
    # Get the current trace span
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
        'username': 'FakeUser',
        'email': 'FakeEmail@example.com',
        'avatar': f'http://{host}{avatar_url}'
    }
    return jsonify(user), 200

@app.route('/connect', methods=['GET'])
def connect():
    result = {
        'success': True
    }
    return jsonify(result), 200

@app.route('/api/version', methods=['GET'])
def get_version():
    """server information"""
    version_info = {
        'version': SERVER_VERSION,
        'build_date': BUILD_DATE,
        'service': 'FT SDK Demo Server'
    }
    return jsonify(version_info), 200

# HTML page rendering, used for mobile WebView display
@app.route('/')
def index():
    name = 'GC_WebView'
    return render_template('index.html', name=name)
    
@app.route('/import_helper')
def import_helper():
    name = 'GC_Demo_Import_Heler'
    return render_template('import_helper.html', name=name)

if __name__ == '__main__':
    # LAN settings
    app.run(host='0.0.0.0', port=8000)
