#!/usr/bin/env python3
"""
data_processor.py

Processes raw scheme data from myscheme.gov.in API into a clean, frontend-friendly format.
Removes unnecessary metadata and keeps only meaningful information for display.
"""

import json
import datetime
from typing import Dict, List, Any


class SchemeDataProcessor:
    def __init__(self, input_file: str = None):
        self.input_file = input_file

    def load_raw_data(self, file_path: str = None) -> Dict[str, Any]:
        """Load raw scheme data from JSON file"""
        file_path = file_path or self.input_file
        if not file_path:
            raise ValueError("No input file specified")

        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)

    def extract_scheme_info(self, scheme: Dict[str, Any]) -> Dict[str, Any]:
        """Extract and clean individual scheme information"""
        fields = scheme.get('fields', {})

        return {
            'id': scheme.get('id'),
            'slug': fields.get('slug'),
            'name': fields.get('schemeName'),
            'short_title': fields.get('schemeShortTitle'),
            'description': fields.get('briefDescription'),
            'category': fields.get('schemeCategory', []),
            'level': fields.get('level'),
            'beneficiary_state': fields.get('beneficiaryState', []),
            'ministry': fields.get('nodalMinistryName'),
            'scheme_for': fields.get('schemeFor'),
            'tags': fields.get('tags', []),
            'close_date': fields.get('schemeCloseDate')
        }

    def process_data(self, raw_data: Dict[str, Any] = None) -> Dict[str, Any]:
        """Process raw data into clean frontend format"""
        if raw_data is None:
            raw_data = self.load_raw_data()

        # Extract schemes
        hits = raw_data.get('data', {}).get('hits', {})
        schemes_raw = hits.get('items', [])

        # Process each scheme
        schemes = []
        for scheme in schemes_raw:
            clean_scheme = self.extract_scheme_info(scheme)
            schemes.append(clean_scheme)

        # Extract summary info
        summary = raw_data.get('data', {}).get('summary', {})
        page_info = hits.get('page', {})

        # Create clean output
        processed_data = {
            'total_schemes': summary.get('total', 0),
            'current_page': page_info.get('pageNumber', 0),
            'total_pages': page_info.get('totalPages', 0),
            'page_size': page_info.get('size', 0),
            'schemes': schemes,
            'category': summary.get('appliedFilters', [{}])[0].get('value', 'Unknown'),
            'processed_at': datetime.datetime.now().isoformat()
        }

        return processed_data

    def save_processed_data(self, processed_data: Dict[str, Any], output_file: str = None) -> str:
        """Save processed data to JSON file"""
        if not output_file:
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            output_file = f"processed_schemes_{timestamp}.json"

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(processed_data, f, indent=2, ensure_ascii=False)

        return output_file


def main():
    """Main processing function"""
    # Find the latest scheme data file
    import glob
    import os

    # Look for scheme_data_*.json files
    data_files = glob.glob("scheme_data_*.json")
    if not data_files:
        print("❌ No scheme data files found")
        return

    # Use the most recent file
    latest_file = max(data_files, key=os.path.getctime)
    print(f"📁 Processing file: {latest_file}")

    # Process the data
    processor = SchemeDataProcessor()
    raw_data = processor.load_raw_data(latest_file)
    processed_data = processor.process_data(raw_data)

    # Save processed data
    output_file = processor.save_processed_data(processed_data)

    print("✅ Processing complete!")
    print(f"📊 Total schemes: {processed_data['total_schemes']}")
    print(f"💾 Saved to: {output_file}")

    # Show sample of first scheme
    if processed_data['schemes']:
        sample = processed_data['schemes'][0]
        print("\n📋 Sample scheme:")
        print(f"  Name: {sample['name']}")
        print(f"  Category: {', '.join(sample['category'])}")
        print(f"  Level: {sample['level']}")
        print(f"  Tags: {', '.join(sample['tags'][:3])}...")


if __name__ == "__main__":
    main()