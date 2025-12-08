import pdfplumber
import pandas as pd
import re

def clean_text(value):
    """Generic text cleaner (no hardcoding)."""
    if value is None:
        return None

    # Normalize whitespace & merge broken lines
    value = re.sub(r"\s*\n\s*", " ", str(value)).strip()

    # Remove duplicate spaces
    value = re.sub(r"\s{2,}", " ", value)

    return value


def normalize_table(df: pd.DataFrame) -> pd.DataFrame:
    """Normalize any detected table without hard-coded columns."""
    
    # Clean all cells
    df = df.applymap(clean_text)

    # Remove rows fully empty
    df = df.dropna(how="all")

    # Sometimes first row becomes header → auto-fix
    # Check if row 0 contains less numeric data (likely header)
    first_row = df.iloc[0].astype(str).str.isnumeric().sum()
    later_rows = df.iloc[1:].astype(str).apply(lambda r: r.str.isnumeric().sum(), axis=1).mean()

    if first_row < later_rows:
        df.columns = df.iloc[0]
        df = df[1:]

    # Remove accidental repeated headers
    df = df[df.apply(lambda r: not all(str(r[c]) == str(df.columns[i]) for i, c in enumerate(df.columns)), axis=1)]

    df = df.reset_index(drop=True)
    return df


def extract_tables_from_pdf(pdf_path):
    with pdfplumber.open(pdf_path) as pdf:
        for page_no, page in enumerate(pdf.pages, start=1):

            tables = page.extract_tables()

            if not tables:
                continue

            print("\n-----------------------------------------")
            print(f"📌 Table-like page detected → Page {page_no}")
            print("-----------------------------------------")

            for tbl in tables:
                df = pd.DataFrame(tbl)

                # Auto-detect and normalize
                normalized_df = normalize_table(df)
                print(normalized_df)

                print("\n" + "-" * 50 + "\n")


# RUN
extract_tables_from_pdf("./../pdfs/pop2016.pdf")
