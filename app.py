import os
from openai import AzureOpenAI
from dotenv import load_dotenv

from flask import (Flask, redirect, render_template, request,
                   send_from_directory, url_for)

app = Flask(__name__)

# OpenAIの設定
AZURE_OPENAI_RESOURCE = os.environ.get('AZURE_OPENAI_RESOURCE')
AZURE_OPENAI_API_KEY = os.environ.get('AZURE_OPENAI_KEY')
AZURE_OPENAI_MODEL = os.environ.get('AZURE_OPENAI_MODEL')
AZURE_OPENAI_ENDPOINT = os.environ.get('AZURE_OPENAI_ENDPOINT')
AZURE_OPENAI_API_VERSION = os.environ.get('AZURE_OPENAI_API_VERSION')


@app.route('/')
def index():
    print('Request for index page received')
   
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Does Azure OpenAI support customer managed keys?"},
        {"role": "assistant", "content": "Yes, customer managed keys are supported by Azure OpenAI."},
        {"role": "user", "content": "Do other Azure AI services support this too?"}
    ]

    client = AzureOpenAI(
        azure_endpoint=AZURE_OPENAI_ENDPOINT,
        api_version=AZURE_OPENAI_API_VERSION,
    )

    # OpenAIへのリクエスト
    chat_completion = client.chat.completions.create(
        messages=messages,
        model=AZURE_OPENAI_MODEL,
        temperature=0,
        max_tokens=5
    )

    # リクエストを取り出し
    response = chat_completion.choices[0].message.content

    return render_template('index.html', response = response)

@app.route('/favicon.ico')
def favicon():
    return send_from_directory(os.path.join(app.root_path, 'static'),
                               'favicon.ico', mimetype='image/vnd.microsoft.icon')

if __name__ == '__main__':
   app.run()
