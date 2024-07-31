import os
import sys
from dotenv import load_dotenv
import google.generativeai as genai

def load_api_key():
    """Load the API key from the .env file."""
    load_dotenv()
    api_key = os.getenv("API_KEY")
    if not api_key:
        print("API key not found. Please set it in the .env file.")
        sys.exit(1)
    return api_key

def configure_model(api_key):
    """Configure and return the Generative Model instance."""
    genai.configure(api_key=api_key)
    return genai.GenerativeModel('gemini-1.5-flash')

def create_prompt(reason):
    """Create and return the structured prompt."""
    return f"""
    Provide a detailed solution for the issue: {reason}. The solution should include:

    1. **What is {reason}?**
    - A clear and concise explanation of what the issue is.

    2. **Why do we get {reason}?**
    - A list of possible causes for the issue.

    3. **How to resolve {reason}?**
    - Step-by-step instructions or code examples on how to fix the issue.
    """

def get_solution(reason):
    """Generate and return the solution for the given reason."""
    api_key = load_api_key()
    model = configure_model(api_key)
    prompt = create_prompt(reason)
    response = model.generate_content(prompt)
    return response.text

def main():
    """Main function to handle command-line arguments and print the solution."""
    if len(sys.argv) != 2:
        print("Usage: python get_gemini_solution.py <reason>")
        sys.exit(1)
    
    reason = sys.argv[1]
    solution = get_solution(reason)
    print(solution)

if __name__ == "__main__":
    main()

