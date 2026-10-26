# ------------------------------------------------------------
# Property Investment Management System
# Author: xKevinx66
# ------------------------------------------------------------
"""
data_visualiser.py

Required functions:
- prop_val_distribution(dataframe, suburb, target_currency="AUD") -> None
- sales_trend(dataframe) -> None

These functions generate and save plots locally (output/ directory).
"""

from __future__ import annotations

import os
import re
from typing import Dict

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# Provided exchange rates to Australian dollars (AUD) per spec.
# Interpretation: 1 AUD = currency_dict[target_currency] * target_currency.
currency_dict: Dict[str, float] = {
    "AUD": 1,
    "USD": 0.66,
    "INR": 54.25,
    "CNY": 4.72,
    "JPY": 93.87,
    "HKD": 5.12,
    "KRW": 860.92,
    "GBP": 0.51,
    "EUR": 0.60,
    "SGD": 0.88,
}


def _ensure_output_dir() -> str:
    out_dir = os.path.join(os.getcwd(), "output")
    os.makedirs(out_dir, exist_ok=True)
    return out_dir


def prop_val_distribution(dataframe: pd.DataFrame, suburb: str, target_currency: str = "AUD") -> None:
    """
    Produce a histogram of property value distribution for a suburb and save it locally.

    Behaviour (required):
    - If target_currency not in currency_dict -> inform user and generate histogram in AUD
    - If suburb does not exist -> inform user and generate histogram for all suburbs
    - Exclude records with missing price values
    - Save the histogram as a file locally

    Args:
        dataframe: Input DataFrame.
        suburb: Suburb to filter, or "all".
        target_currency: Currency code; default "AUD".

    Returns:
        None
    """
    try:
        if not isinstance(dataframe, pd.DataFrame) or dataframe.empty:
            raise ValueError("dataframe is empty or invalid. Load data first.")
        if not isinstance(suburb, str) or not suburb.strip():
            raise ValueError("suburb must be a non-empty string.")
        if not isinstance(target_currency, str) or not target_currency.strip():
            raise ValueError("target_currency must be a non-empty string.")

        out_dir = _ensure_output_dir()

        suburb_key = suburb.strip()
        df_use = dataframe

        if suburb_key.lower() != "all":
            if "suburb" not in dataframe.columns:
                raise KeyError("dataframe must contain a 'suburb' column.")
            mask = dataframe["suburb"].astype(str).str.lower() == suburb_key.lower()
            if not mask.any():
                print(f"[Warn] Suburb not found: {suburb_key}. Using all suburbs.")
                suburb_key = "all"
            else:
                df_use = dataframe.loc[mask].copy()

        cur = target_currency.strip().upper()
        if cur not in currency_dict:
            print(f"[Warn] Currency not found: {cur}. Using AUD.")
            cur = "AUD"

        prices = pd.to_numeric(df_use["price"], errors="coerce").dropna()
        if prices.empty:
            print("[Warn] No valid price values found. Histogram not generated.")
            return

        converted = prices.to_numpy(dtype=float) * float(currency_dict[cur])

        plt.figure()
        plt.hist(converted, bins=30)
        plt.xlabel(f"Property Price ({cur})")
        plt.ylabel("Count")
        title_sub = suburb_key if suburb_key.lower() != "all" else "All Suburbs"
        plt.title(f"Property Value Distribution - {title_sub} ({cur})")

        safe_suburb = re.sub(r'[^A-Za-z0-9]+', '_', title_sub).strip('_')
        file_name = f"prop_val_distribution_{safe_suburb}_{cur}.png"
        file_path = os.path.join(out_dir, file_name)
        plt.tight_layout()
        plt.savefig(file_path, dpi=200)
        plt.close()

        print(f"[OK] Histogram saved: {file_path}")
    except Exception as exc:
        print(f"[Error] prop_val_distribution failed: {exc}")


def sales_trend(dataframe: pd.DataFrame) -> None:
    """
    Calculate and visualise the number of properties sold in each year as a line chart.

    The line chart is saved as an image file locally.

    Args:
        dataframe: Input DataFrame (must contain 'sold_date').

    Returns:
        None
    """
    try:
        if not isinstance(dataframe, pd.DataFrame) or dataframe.empty:
            raise ValueError("dataframe is empty or invalid. Load data first.")
        if "sold_date" not in dataframe.columns:
            raise KeyError("dataframe must contain a 'sold_date' column.")

        out_dir = _ensure_output_dir()

        sold = dataframe["sold_date"].dropna().astype(str)
        if sold.empty:
            print("[Warn] No sold_date values found. Trend not generated.")
            return

        # Expect day-first dates like "3/4/2023"
        dates = pd.to_datetime(sold, errors="coerce", dayfirst=True)
        dates = dates.dropna()
        if dates.empty:
            print("[Warn] sold_date parsing failed. Trend not generated.")
            return

        years = dates.dt.year
        counts = years.value_counts().sort_index()

        plt.figure()
        plt.plot(counts.index.to_numpy(), counts.values)
        plt.xlabel("Year")
        plt.ylabel("Number of Properties Sold")
        plt.title("Sales Trend by Year")
        plt.tight_layout()

        file_path = os.path.join(out_dir, "sales_trend.png")
        plt.savefig(file_path, dpi=200)
        plt.close()

        print(f"[OK] Sales trend saved: {file_path}")
    except Exception as exc:
        print(f"[Error] sales_trend failed: {exc}")


class DataVisualiser:
    """OOP wrapper around the required visualisation functions."""

    def prop_val_distribution(self, dataframe: pd.DataFrame, suburb: str, target_currency: str = "AUD") -> None:
        prop_val_distribution(dataframe, suburb, target_currency)

    def sales_trend(self, dataframe: pd.DataFrame) -> None:
        sales_trend(dataframe)

