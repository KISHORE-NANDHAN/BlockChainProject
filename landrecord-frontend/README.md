

---

````markdown
# Land Records Management System (Django Backend)

This is the backend of the Land Records Management System built with Django. It supports OTP-based email verification using environment variables.

## 🛠 Features

- Django-based web backend
- Email OTP authentication
- Environment-based configuration using `python-decouple`

---

## 📦 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/krishnamohannaik/landrecord-frontend.git
cd landrecord-frontend
````

> Make sure you're in the `myproject` folder where `manage.py` and `requirements.txt` are located.

---

### 2. Create Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate   # For Linux/macOS
venv\Scripts\activate      # For Windows
```

---

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

---

### 4. Create `.env` File

Create a `.env` file in the `myproject` directory. Example:

```ini
EMAIL_HOST_USER=your_email@example.com
EMAIL_HOST_PASSWORD=your_app_password
```

> ⚠️ Replace with your actual email and app-specific password (not your main password).

---

### 5. Run Migrations and Start Server

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py runserver
```

---

## ⚠️ Security Notes

* Do **not** share your `.env` file publicly.
* It has been added to `.gitignore` to avoid committing sensitive data.

---

## 📁 Project Structure

```
myproject/
├── manage.py
├── .env                  # Add this manually
├── myapp/
└── myproject/
```

---

## 🔗 Author

* GitHub: [krishnamohannaik](https://github.com/krishnamohannaik)

```
```
