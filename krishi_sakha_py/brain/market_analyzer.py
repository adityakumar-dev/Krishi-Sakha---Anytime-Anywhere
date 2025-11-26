"""
Market Analyzer for Uttarakhand Crops
Searches for current market prices, demand, and trends for Dehradun region crops
"""

import logging
import asyncio
from typing import Dict, List, Optional
from modules.search.searxng_json import searxng_search
from modules.scrapper.scrapper import json_scrapped

logger = logging.getLogger(__name__)


async def get_market_analysis_for_crops(
    crop_names: List[str],
    region: str = "Uttarakhand"
) -> str:
    """
    Get current market prices, demand, and trends for specified crops in Uttarakhand.
    
    Args:
        crop_names: List of crop names (e.g., ['wheat', 'rice', 'maize'])
        region: Region name (default: Uttarakhand)
    
    Returns:
        Formatted market analysis string ready for model consumption
    """
    
    try:
        logger.info(f"Fetching market analysis for crops: {crop_names}")
        
        market_data = {}
        
        for crop in crop_names:
            try:
                # Search for current market prices and trends
                search_query = f"{crop} market price {region} Dehradun 2024 2025"
                logger.info(f"Searching for: {search_query}")
                
                results = await json_scrapped(search_query)
                
                if results:
                    market_data[crop] = {
                        "search_results": results,
                        "status": "found"
                    }
                else:
                    market_data[crop] = {
                        "search_results": [],
                        "status": "no_results"
                    }
                
                # Small delay between searches
                await asyncio.sleep(0.5)
                
            except Exception as e:
                logger.warning(f"Error fetching market data for {crop}: {e}")
                market_data[crop] = {
                    "search_results": [],
                    "status": "error",
                    "error": str(e)
                }
        
        # Format the market analysis
        formatted_analysis = format_market_analysis(market_data, region)
        return formatted_analysis
        
    except Exception as e:
        logger.error(f"Error in get_market_analysis_for_crops: {e}")
        return f"Market data unavailable: {str(e)}"


def format_market_analysis(market_data: Dict, region: str) -> str:
    """
    Format market data into a readable string for the model.
    
    Args:
        market_data: Dictionary with market information
        region: Region name
    
    Returns:
        Formatted string with market analysis
    """
    
    formatted = f"\n=== CURRENT MARKET ANALYSIS FOR {region.upper()} CROPS ===\n\n"
    
    for crop, data in market_data.items():
        formatted += f"📊 {crop.upper()}\n"
        
        if data["status"] == "error":
            formatted += f"   Status: Error fetching data - {data.get('error', 'Unknown')}\n"
        elif data["status"] == "no_results":
            formatted += f"   Status: No recent market data found\n"
        else:
            # Parse search results
            results = data.get("search_results", [])
            
            if results:
                formatted += f"   Market Information Found: {len(results)} results\n"
                
                # Extract key information from first few results
                for i, result in enumerate(results[:3]):
                    if isinstance(result, dict):
                        title = result.get("title", "")
                        url = result.get("url", "")
                        snippet = result.get("snippet", "")[:150]
                        
                        formatted += f"\n   Source {i+1}: {title}\n"
                        if snippet:
                            formatted += f"   Details: {snippet}...\n"
                        if url:
                            formatted += f"   URL: {url}\n"
            else:
                formatted += f"   Status: No search results available\n"
        
        formatted += "\n"
    
    formatted += "=== END MARKET ANALYSIS ===\n"
    return formatted


async def get_uttarakhand_cultivation_patterns(
    crops: List[str]
) -> str:
    """
    Search for best cultivation patterns and practices specific to Uttarakhand.
    
    Args:
        crops: List of crop names
    
    Returns:
        Formatted cultivation patterns string
    """
    
    try:
        logger.info(f"Fetching Uttarakhand cultivation patterns for: {crops}")
        
        patterns_data = {}
        
        for crop in crops:
            try:
                # Search for cultivation patterns specific to Uttarakhand
                search_query = f"{crop} cultivation Uttarakhand best practices timing planting"
                logger.info(f"Searching patterns for: {search_query}")
                
                results = await json_scrapped(search_query)
                
                patterns_data[crop] = results if results else []
                await asyncio.sleep(0.5)
                
            except Exception as e:
                logger.warning(f"Error fetching patterns for {crop}: {e}")
                patterns_data[crop] = []
        
        # Format the patterns
        formatted_patterns = format_cultivation_patterns(patterns_data)
        return formatted_patterns
        
    except Exception as e:
        logger.error(f"Error in get_uttarakhand_cultivation_patterns: {e}")
        return f"Cultivation patterns unavailable: {str(e)}"


def format_cultivation_patterns(patterns_data: Dict) -> str:
    """
    Format cultivation patterns into readable string.
    
    Args:
        patterns_data: Dictionary with pattern information
    
    Returns:
        Formatted string
    """
    
    formatted = "\n=== UTTARAKHAND CULTIVATION PATTERNS & BEST PRACTICES ===\n\n"
    
    for crop, results in patterns_data.items():
        formatted += f"🌾 {crop.upper()}\n"
        
        if not results:
            formatted += f"   No specific pattern data found. Use general practices.\n"
        else:
            formatted += f"   Recommended Practices (from Uttarakhand sources):\n"
            
            for i, result in enumerate(results[:2]):
                if isinstance(result, dict):
                    title = result.get("title", "")
                    snippet = result.get("snippet", "")[:200]
                    
                    if title:
                        formatted += f"   • {title}\n"
                    if snippet:
                        formatted += f"     {snippet}...\n"
        
        formatted += "\n"
    
    formatted += "=== END CULTIVATION PATTERNS ===\n"
    return formatted
