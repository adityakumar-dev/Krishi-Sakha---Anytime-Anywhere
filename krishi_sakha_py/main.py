from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())

from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from langchain_ollama import ChatOllama
from routes import search, test, chat, voice, language, post , user
app = FastAPI()


@app.get("/")
async def root():
    return {"msg": "Ollama+LangChain+FastAPI running"}



app.include_router(test.router)
app.include_router(chat.router)
app.include_router(voice.router)
app.include_router(search.router)
app.include_router(language.router)
app.include_router(post.router)
app.include_router(user.router)