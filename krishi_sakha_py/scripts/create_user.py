#!/usr/bin/env python3
"""
Script to create a new user in Supabase with role-based access.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from modules.auth.create_user import create_user

def main():
    print("Welcome to Krishi Sakha User Creation Script")
    print("Available roles: normal, asha, panchayat, gov")
    print()

    # Ask for role
    while True:
        role = input("Enter the role for the new user (normal/asha/panchayat/gov): ").strip().lower()
        if role in ['normal', 'asha', 'panchayat', 'gov']:
            break
        else:
            print("Invalid role. Please choose from: normal, asha, panchayat, gov")

    print(f"Selected role: {role}")
    print()

    # Ask for email
    while True:
        email = input("Enter the email address: ").strip()
        if '@' in email and '.' in email:
            break
        else:
            print("Invalid email format. Please enter a valid email address.")

    # Ask for password
    while True:
        password = input("Enter the password (minimum 6 characters): ").strip()
        if len(password) >= 6:
            break
        else:
            print("Password must be at least 6 characters long.")

    # Confirm
    print()
    print("Creating user with the following details:")
    print(f"Email: {email}")
    print(f"Role: {role}")
    confirm = input("Confirm? (y/n): ").strip().lower()
    if confirm != 'y':
        print("User creation cancelled.")
        return

    # Create user
    try:
        result = create_user(email=email, password=password, app_role=role)
        print()
        print("User creation result:")
        print(result)
        if 'user' in result:
            print("User created successfully!")
        else:
            print("Failed to create user. Check the error above.")
    except Exception as e:
        print(f"Error creating user: {e}")

if __name__ == "__main__":
    main()
