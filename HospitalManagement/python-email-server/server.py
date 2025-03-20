from flask import Flask, request, jsonify
from flask_cors import CORS
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from .env

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Define greeting templates for different roles
GREETING_TEMPLATES = {
    "doctor": """
    Dear Doctor,

    Welcome to our Hospital Management System!

    Your login credentials are as follows:
    Email: {email}
    Temporary Password: {temp_password}

    Please log in and change your password immediately for security.

    Best regards,
    Team - 09 , HMS
    Infosys
    """,

    "admin": """
    Dear Hospital Administrator,

    Welcome to our Healthcare Management System!

    Your login credentials are as follows:
    Email: {email}
    Temporary Password: {temp_password}

    Please log in and change your password immediately for security.

    Best regards,
    Team - 09 , HMS
    Infosys

    """,
}


@app.route('/send-email', methods=['POST'])
def send_email():
    data = request.get_json()
    recipient = data.get('email')
    temp_password = data.get('tempPassword')
    role = data.get('role', 'default').lower()  # Get role from request, default to 'default' if not provided

    if not recipient or not temp_password:
        return jsonify({"error": "Email and temporary password are required"}), 400

    sender_email = os.getenv("GMAIL_EMAIL")
    sender_password = os.getenv("GMAIL_APP_PASSWORD")

    if not sender_email or not sender_password:
        return jsonify({"error": "Email configuration is missing"}), 500

    # Get the appropriate greeting template based on role
    greeting_template = GREETING_TEMPLATES.get(role, GREETING_TEMPLATES['default'])
    
    # Format the greeting with user's information
    body = greeting_template.format(
        email=recipient,
        temp_password=temp_password
    )

    # Create MIME message
    msg = MIMEMultipart()
    msg['From'] = sender_email
    msg['To'] = recipient
    msg['Subject'] = f"Welcome to our Platform - {role.title()} Access"
    msg.attach(MIMEText(body, 'plain'))

    try:
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(sender_email, sender_password)
        server.sendmail(sender_email, recipient, msg.as_string())
        server.quit()
        return jsonify({"message": f"Email sent successfully to {role}"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5001) 
