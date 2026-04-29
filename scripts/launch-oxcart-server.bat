@echo off
title Oxcart Llama Server CUDA

set LLAMA_ARG_HF_REPO=bartowski/FINAL-Bench_Darwin-35B-A3B-Opus-GGUF:IQ2_S
set LLAMA_ARG_ALIAS=Oxcart_Draw_Server_CUDA
set LLAMA_ARG_DEVICE=CUDA0
set LLAMA_ARG_NO_WARMUP=1
set LLAMA_ARG_SPLIT_MODE=none
set LLAMA_ARG_MAIN_GPU=0
set LLAMA_ARG_CTX_SIZE=132000
set LLAMA_ARG_N_GPU_LAYERS=-1
set LLAMA_ARG_HOST=127.0.0.1
set LLAMA_ARG_PORT=8080
set LLAMA_ARG_TEMP=0.00
set LLAMA_ARG_TOP_P=0.9
set LLAMA_ARG_TOP_K=40
set LLAMA_ARG_REPEAT_PENALTY=1.15
set LLAMA_ARG_REPEAT_LAST_N=2048
set LLAMA_ARG_IMAGE_MIN_TOKENS=512
set LLAMA_ARG_IMAGE_MAX_TOKENS=512
set LLAMA_ARG_WEBUI_CONFIG={"showSystemMessage":false,"showThoughtInProgress":false,"showMessageStats":false,"showRawModelNames":false,"pdfAsImage":true,"temperature":0.00,"top_p":0.9,"top_k":40,"repeat_penalty":1.15,"repeat_last_n":2048}

llama-server.exe
