"""
Context Prioritizer: Intelligently structures and filters agricultural data
to prevent model context overload and ensure focused crop recommendations.

This module prioritizes data in order of importance:
1. Weather-suitable crops (top 5 by profit & demand)
2. Government schemes matching those crops
3. Comparison table for side-by-side analysis
4. Sensor-based soil recommendations
5. Detailed historical data (if needed)
"""

import csv
import json
from typing import List, Dict, Tuple
from datetime import datetime
import re


class ContextPrioritizer:
    """Intelligent context structuring for crop advisory system."""

    def __init__(self, dehradun_csv_path: str, schemes_csv_path: str):
        """Initialize with paths to crop and scheme data files."""
        self.dehradun_csv_path = dehradun_csv_path
        self.schemes_csv_path = schemes_csv_path
        self.crops_data = self._load_crops()
        self.schemes_data = self._load_schemes()

    def _load_crops(self) -> List[Dict]:
        """Load all crop data from CSV."""
        crops = []
        try:
            with open(self.dehradun_csv_path, 'r', encoding='utf-8') as f:
                csv_reader = csv.DictReader(f)
                for row in csv_reader:
                    crops.append(row)
        except Exception as e:
            print(f"Error loading crops: {e}")
        return crops

    def _load_schemes(self) -> List[Dict]:
        """Load all scheme data from CSV."""
        schemes = []
        try:
            with open(self.schemes_csv_path, 'r', encoding='utf-8') as f:
                csv_reader = csv.DictReader(f)
                for row in csv_reader:
                    schemes.append(row)
        except Exception as e:
            print(f"Error loading schemes: {e}")
        return schemes

    def _extract_profit_percentage(self, profit_str: str) -> float:
        """Extract profit percentage from strings like '~63%' or '63%'."""
        try:
            match = re.search(r'(\d+(?:\.\d+)?)', str(profit_str))
            return float(match.group(1)) if match else 0.0
        except:
            return 0.0

    def _extract_numeric_value(self, value_str: str) -> float:
        """Extract numeric value from strings with currencies/units."""
        try:
            match = re.search(r'(\d+(?:,\d+)*(?:\.\d+)?)', str(value_str).replace(',', ''))
            return float(match.group(1)) if match else 0.0
        except:
            return 0.0

    def _calculate_relevance_score(self, crop: Dict, weather_keywords: List[str]) -> Tuple[float, str]:
        """
        Calculate crop relevance score based on weather suitability and profitability.
        
        Returns:
            Tuple of (score, reason)
        """
        score = 0.0
        reason = []

        # Check weather suitability match
        suitability = str(crop.get("Suitability (Weather/Soil)", "")).lower()
        weather_match = sum(1 for keyword in weather_keywords if keyword.lower() in suitability)
        
        if weather_match > 0:
            score += weather_match * 25
            reason.append(f"matches weather ({weather_match} factors)")

        # Profitability score (profit margin)
        profit = self._extract_profit_percentage(crop.get("Avg Profit Margin", "0"))
        profit_score = min(40, (profit / 100) * 40)  # Cap at 40 points
        score += profit_score
        if profit > 50:
            reason.append(f"high profit ({int(profit)}%)")
        elif profit > 30:
            reason.append(f"medium profit ({int(profit)}%)")

        # Market demand boost
        demand = str(crop.get("Market Demand", "")).lower()
        if "very high" in demand:
            score += 25
            reason.append("very high demand")
        elif "high" in demand:
            score += 15
            reason.append("high demand")
        elif "growing" in demand:
            score += 10
            reason.append("growing demand")

        # Risk factor penalty
        risk = str(crop.get("Risk Factors", "")).lower()
        if "pest" in risk:
            score -= 5
            reason.append("pest risk (⚠️)")
        if "flood" in risk or "waterlogging" in risk:
            score -= 8
            reason.append("flood risk (⚠️)")

        return score, " • ".join(reason) if reason else "Moderate potential"

    def filter_crops_by_weather(
        self, weather_context: str, top_n: int = 10
    ) -> List[Dict]:
        """
        Filter and rank crops based on weather conditions.
        
        Args:
            weather_context: Weather description from frontend
            top_n: Number of top crops to return (increased to 10 for Gemini's larger context window)
            
        Returns:
            List of top N crops with relevance scores
        """
        # Extract weather keywords from context
        keywords = [
            "rainfall", "rain", "wet", "humid",
            "temperature", "hot", "cold", "warm",
            "drought", "dry", "arid",
            "irrigation", "moisture", "soil",
            "loam", "clay", "sandy"
        ]
        
        # Score all crops
        ranked_crops = []
        for crop in self.crops_data:
            score, reason = self._calculate_relevance_score(crop, keywords)
            ranked_crops.append({
                **crop,
                "_relevance_score": score,
                "_relevance_reason": reason
            })

        # Sort by relevance score
        ranked_crops.sort(key=lambda x: x["_relevance_score"], reverse=True)
        
        return ranked_crops[:top_n]

    def get_schemes_for_crops(
        self, crop_names: List[str], state: str = "Uttarakhand"
    ) -> List[Dict]:
        """
        Get government schemes applicable to selected crops.
        
        Args:
            crop_names: List of crop names to match
            state: State name for scheme filtering
            
        Returns:
            List of relevant schemes
        """
        relevant_schemes = []
        crop_names_lower = [name.lower() for name in crop_names]
        
        for scheme in self.schemes_data:
            # Check if scheme applies to this state
            beneficiary_states = str(scheme.get('beneficiarystate', '[]')).lower()
            
            # Parse beneficiary states - handles formats like ['Uttarakhand'] or 'All'
            state_match = (
                state.lower() in beneficiary_states or 
                'all' in beneficiary_states or
                'uttar' in beneficiary_states  # Handles 'Uttarakhand'
            )
            
            if not state_match:
                continue
            
            # Get scheme info - try multiple column name variations
            scheme_name = (
                scheme.get('schemename') or 
                scheme.get('schemanme') or  # Handle typo in CSV
                scheme.get('schemeshorttitle') or 
                'Unknown'
            )
            
            # Get scheme for field
            scheme_for = str(scheme.get('schemefor', '')).lower()
            scheme_desc = str(scheme.get('briefdescription', '')).lower()
            
            # Match agriculture-related schemes
            agriculture_keywords = [
                'farmer', 'agriculture', 'cultivation', 'crop', 'farm',
                'subsidy', 'loan', 'credit', 'support', 'assistance'
            ]
            
            is_ag_scheme = any(
                term in scheme_for or term in scheme_desc 
                for term in agriculture_keywords
            )
            
            if is_ag_scheme and scheme_name != 'Unknown':
                relevant_schemes.append({
                    'name': scheme_name,
                    'short_title': scheme.get('schemeshorttitle', scheme_name),
                    'description': scheme.get('briefdescription', '')[:200],  # Truncate long descriptions
                    'category': scheme.get('schemecategory', ''),
                    'ministry': scheme.get('nodalministryname', ''),
                    'applicable_crops': crop_names
                })
        
        # Return unique schemes (by name)
        seen = set()
        unique_schemes = []
        for scheme in relevant_schemes:
            if scheme['name'] not in seen:
                seen.add(scheme['name'])
                unique_schemes.append(scheme)
        
        # Return top 20 schemes (increased from 10 for better coverage with Gemini)
        return unique_schemes[:20] if unique_schemes else []

    def create_comparison_table(self, crops: List[Dict]) -> str:
        """
        Create a simple, beautifully structured comparison of selected crops.
        Uses key-value pairs instead of markdown tables for better readability.
        
        Args:
            crops: List of crop dictionaries with data
            
        Returns:
            Formatted comparison string
        """
        if not crops:
            return "No crops available for comparison."

        comparison_lines = []
        
        for i, crop in enumerate(crops, 1):
            crop_name = crop.get("Crop Name", "Unknown").strip()
            yield_info = crop.get("Avg Yield (per acre)", "N/A").strip()
            cost = self._extract_numeric_value(crop.get("Cost of Cultivation (₹)", "0"))
            profit = self._extract_profit_percentage(crop.get("Avg Profit Margin", "0"))
            demand = crop.get("Market Demand", "N/A").strip()
            
            # Get risk factors - clean them up
            risk_raw = crop.get("Risk Factors", "N/A").strip()
            risk = risk_raw.split(",")[0][:40] if risk_raw else "Low"
            
            # Format the row with proper spacing
            cost_formatted = f"₹{int(cost):,}" if cost > 0 else "N/A"
            
            # Build key-value pair format
            comparison_lines.append(f"""
{i}. {crop_name}
   • Yield per acre: {yield_info}
   • Cost of cultivation: {cost_formatted}
   • Profit margin: {int(profit)}%
   • Market demand: {demand}
   • Risk factor: {risk}""")

        return "\n".join(comparison_lines)

    def create_prioritized_context(
        self,
        weather_context: str,
        sensor_data: Dict,
        state: str = "Uttarakhand",
        top_crops: int = 10
    ) -> str:
        """
        Create prioritized, structured context for the model.
        
        This structures data in order of importance to guide model focus:
        1. Current conditions (weather + sensor)
        2. Top recommended crops (filtered & ranked) - now 10 crops for Gemini's larger context
        3. Government schemes (matching crops & state) - now 20 schemes
        4. Comparison table (for farmer decision-making)
        5. Detailed guidance (soil, risk, market)
        
        Args:
            weather_context: Weather information from frontend
            sensor_data: Current sensor readings
            state: Target state
            top_crops: Number of top crops to recommend (increased to 10)
            
        Returns:
            Structured context string for model
        """
        # Step 1: Filter crops by weather (now returns top 10)
        recommended_crops = self.filter_crops_by_weather(weather_context, top_crops)
        
        if not recommended_crops:
            return "Unable to process weather data. Please try again."
        
        # Step 2: Get crop names for scheme filtering
        crop_names = [crop["Crop Name"] for crop in recommended_crops]
        
        # Step 3: Get applicable schemes (now returns top 20)
        applicable_schemes = self.get_schemes_for_crops(crop_names, state)
        
        # Step 4: Create comparison table
        comparison_table = self.create_comparison_table(recommended_crops)
        
        # Step 5: Build prioritized context with expanded information
        context = f"""
═══════════════════════════════════════════════════════════════════════════════
🌾 PRIORITIZED CROP ADVISORY CONTEXT FOR {state.upper()}
═══════════════════════════════════════════════════════════════════════════════

📍 CURRENT CONDITIONS (Priority 1 - Most Important)
─────────────────────────────────────────────────────
{weather_context}

📊 Sensor Status: Moisture {sensor_data.get('moisture', 'N/A')}%, Temperature {sensor_data.get('temperature', 'N/A')}°C, Humidity {sensor_data.get('humidity', 'N/A')}%
   (Use these readings to refine crop soil requirements if available)

═══════════════════════════════════════════════════════════════════════════════
🏆 TOP {len(recommended_crops)} RECOMMENDED CROPS FOR CURRENT CONDITIONS (Priority 2)
─────────────────────────────────────────────────────────────────────────────
{self._format_crop_recommendations(recommended_crops)}

═══════════════════════════════════════════════════════════════════════════════
📋 COMPREHENSIVE CROP COMPARISON TABLE (Priority 3 - For Farmer Decision Making)
─────────────────────────────────────────────────────────────────────────────
{comparison_table}

═══════════════════════════════════════════════════════════════════════════════
🏛️ APPLICABLE GOVERNMENT SCHEMES FOR {state.upper()} (Priority 4)
─────────────────────────────────────────────────────────────────────────────
Total Available Schemes: {len(applicable_schemes)}

{self._format_schemes(applicable_schemes, crop_names)}

═══════════════════════════════════════════════════════════════════════════════
💡 KEY RECOMMENDATIONS & INSIGHTS
─────────────────────────────────────────────────────────────────────────────
1. **Weather Match**: All crops above are suitable for current weather conditions
2. **Most Profitable**: {recommended_crops[0]['Crop Name']} offers {self._extract_profit_percentage(recommended_crops[0].get('Avg Profit Margin', '0'))}% profit margin
3. **Market Opportunity**: Focus on crops with "Very High" or "High" market demand for better returns
4. **Government Support**: {len(applicable_schemes)} schemes are available for subsidies and financial assistance
5. **Risk Management**: Consider risk factors listed - diversify if possible
6. **Sensor Data Integration**: Current soil moisture ({sensor_data.get('moisture', 'N/A')}%) and temperature ({sensor_data.get('temperature', 'N/A')}°C) are optimal for the top recommended crops

═══════════════════════════════════════════════════════════════════════════════
📈 DETAILED CROP INFORMATION (Full Data for Model Analysis)
─────────────────────────────────────────────────────────────────────────────
{self._format_detailed_crop_info(recommended_crops)}

═══════════════════════════════════════════════════════════════════════════════
"""
        
        return context

    def _format_crop_recommendations(self, crops: List[Dict]) -> str:
        """Format crop recommendations with ranking and details."""
        lines = []
        for i, crop in enumerate(crops, 1):
            name = crop.get("Crop Name", "Unknown")
            crop_yield = crop.get("Avg Yield (per acre)", "N/A")
            profit = self._extract_profit_percentage(crop.get("Avg Profit Margin", "0"))
            demand = crop.get("Market Demand", "N/A")
            reason = crop.get("_relevance_reason", "Recommended")
            
            lines.append(f"""{i}. **{name}**
   ├─ Yield: {crop_yield}
   ├─ Profit Margin: {int(profit)}%
   ├─ Market Demand: {demand}
   └─ Reason: {reason}
""")
        
        return "\n".join(lines)

    def _format_schemes(self, schemes: List[Dict], crop_names: List[str]) -> str:
        """Format schemes for display."""
        if not schemes:
            return "No specific schemes found for selected crops. Check with local agriculture department."
        
        lines = []
        for i, scheme in enumerate(schemes, 1):
            name = scheme.get('name', 'Unknown')
            short_title = scheme.get('short_title', '')
            category = scheme.get('category', 'General')
            ministry = scheme.get('ministry', 'Unknown')
            
            lines.append(f"""{i}. **{short_title or name}**
   ├─ Category: {category}
   ├─ Ministry: {ministry}
   ├─ Applicable to: {', '.join(scheme.get('applicable_crops', ['Selected crops']))}
   └─ For more info: Contact local agriculture office
""")
        
        return "\n".join(lines)

    def _format_detailed_crop_info(self, crops: List[Dict]) -> str:
        """Format detailed information for all crops (for Gemini's larger context window)."""
        lines = []
        
        for crop in crops:
            name = crop.get("Crop Name", "Unknown")
            all_info = {
                "Land Required": crop.get("Land Required (per acre)", "N/A"),
                "Avg Yield": crop.get("Avg Yield (per acre)", "N/A"),
                "Cultivation Cost": crop.get("Cost of Cultivation (₹)", "N/A"),
                "Selling Price": crop.get("Selling Price (₹/quintal or per kg)", "N/A"),
                "Profit Margin": crop.get("Avg Profit Margin", "N/A"),
                "Market Demand": crop.get("Market Demand", "N/A"),
                "Weather/Soil Suitability": crop.get("Suitability (Weather/Soil)", "N/A"),
                "Risk Factors": crop.get("Risk Factors", "N/A"),
                "Recommended For": crop.get("Recommended For", "N/A"),
            }
            
            lines.append(f"\n📌 **{name}**")
            for key, value in all_info.items():
                lines.append(f"   • {key}: {value}")
        
        return "\n".join(lines)


def get_prioritized_context(
    weather_context: str,
    sensor_data: Dict,
    state: str,
    dehradun_csv: str,
    schemes_csv: str
) -> str:
    """
    Convenience function to get prioritized context.
    
    Args:
        weather_context: Weather description
        sensor_data: Sensor readings dict
        state: Target state
        dehradun_csv: Path to dehradun_crop.csv
        schemes_csv: Path to schemes CSV
        
    Returns:
        Prioritized context string for model (now with 10 crops and 20 schemes for Gemini)
    """
    prioritizer = ContextPrioritizer(dehradun_csv, schemes_csv)
    return prioritizer.create_prioritized_context(
        weather_context,
        sensor_data,
        state,
        top_crops=10  # Increased from 5 to 10 for Gemini's larger context window
    )
