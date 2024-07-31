import google.generativeai as genai
import os
import sys
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

def get_solution(reason):
    api_key = os.getenv("API_KEY")
    if not api_key:
        print("API key not found. Please set it in the .env file.")
        sys.exit(1)

    genai.configure(api_key=api_key)

    model = genai.GenerativeModel('gemini-1.5-flash')

    response = model.generate_content(f"Provide a solution for the issue: {reason} in short and detail points")
    return response.text

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python get_gemini_solution.py <reason>")
        sys.exit(1)

    reason = sys.argv[1]
    solution = get_solution(reason)
    print(solution)
