#!/bin/bash

# Quick Setup Script for Enhanced PDF Processing
# Run this to ensure all dependencies are installed

echo "=================================="
echo "Enhanced PDF Parser Setup"
echo "=================================="
echo ""

# Check Python version
echo "1. Checking Python version..."
python3 --version
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "2. Creating virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "2. Virtual environment already exists"
fi
echo ""

# Activate virtual environment
echo "3. Activating virtual environment..."
source venv/bin/activate
echo "✅ Virtual environment activated"
echo ""

# Install/upgrade dependencies
echo "4. Installing required packages..."
pip install --upgrade pip
pip install pdfplumber
pip install PyPDF2
pip install google-generativeai
pip install chromadb
pip install sentence-transformers
pip install langchain
pip install python-dotenv
echo "✅ All packages installed"
echo ""

# Check .env file
echo "5. Checking environment variables..."
if [ -f ".env" ]; then
    if grep -q "GEMINI_API_KEY" .env; then
        echo "✅ GEMINI_API_KEY found in .env"
    else
        echo "⚠️  GEMINI_API_KEY not found in .env"
        echo "   Please add: GEMINI_API_KEY=your_key_here"
    fi
else
    echo "⚠️  .env file not found"
    echo "   Creating .env template..."
    echo "GEMINI_API_KEY=your_gemini_api_key_here" > .env
    echo "   Please edit .env and add your API key"
fi
echo ""

# Create necessary directories
echo "6. Creating required directories..."
mkdir -p chroma_db
mkdir -p data/pdfs
echo "✅ Directories created"
echo ""

# Check if pop2016.pdf exists
echo "7. Checking for PDF file..."
if [ -f "data/pdfs/pop2016.pdf" ]; then
    echo "✅ pop2016.pdf found"
else
    echo "⚠️  pop2016.pdf not found in data/pdfs/"
    echo "   Please place your PDF file there"
fi
echo ""

echo "=================================="
echo "Setup Complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Ensure GEMINI_API_KEY is set in .env"
echo "2. Place pop2016.pdf in data/pdfs/ directory"
echo "3. Test detection: python scripts/test_content_detection.py"
echo "4. Full processing: python scripts/process_pop2016_to_vectordb.py"
echo ""
echo "For help, see: SOLUTION_SUMMARY.md"
