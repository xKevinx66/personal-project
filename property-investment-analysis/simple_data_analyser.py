# ------------------------------------------------------------
# Property Investment Management System
# Author: xKevinx66
# ------------------------------------------------------------
"""
simple_data_analyser.py

Core data loading, analysis, and algorithmic search utilities.

Required functions (per spec):
- extract_property_info(file_path) -> pandas.DataFrame
- currency_exchange(dataframe, exchange_rate) -> numpy.ndarray
- suburb_summary(dataframe, suburb) -> None
- avg_land_size(dataframe, suburb) -> float | None
- locate_price(target_price, data, target_suburb) -> bool

The implementation is also wrapped in the SimpleDataAnalyser class to satisfy OOP
requirements without changing the required function signatures.
"""

from __future__ import annotations

import os
from typing import List, Optional

import numpy as np
import pandas as pd


def extract_property_info(file_path: str) -> pd.DataFrame:
    """
    Read the property CSV file and return a DataFrame.

    Args:
        file_path: Path to the CSV file.

    Returns:
        A pandas DataFrame of the property data.
    """
    try:
        if not isinstance(file_path, str) or not file_path.strip():
            raise ValueError("file_path must be a non-empty string.")
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
        df = pd.read_csv(file_path)
        if df.empty:
            print("Warning: CSV loaded but contains no rows.")
        return df
    except Exception as exc:  # keep user-friendly; do not crash
        print(f"[Error] Failed to load CSV: {exc}")
        return pd.DataFrame()


def currency_exchange(dataframe: pd.DataFrame, exchange_rate: float) -> np.ndarray:
    """
    Convert property prices from AUD into a target currency.

    Args:
        dataframe: Input DataFrame that contains a 'price' column.
        exchange_rate: Exchange rate to AUD.

    Returns:
        Numpy array of converted prices (may include NaN).
    """
    try:
        if not isinstance(dataframe, pd.DataFrame):
            raise TypeError("dataframe must be a pandas DataFrame.")
        if "price" not in dataframe.columns:
            raise KeyError("dataframe must contain a 'price' column.")
        if not isinstance(exchange_rate, (int, float)) or exchange_rate <= 0:
            raise ValueError("exchange_rate must be a positive number.")

        prices = pd.to_numeric(dataframe["price"], errors="coerce")
        converted = prices.to_numpy(dtype=float) * float(exchange_rate)
        return converted
    except Exception as exc:
        print(f"[Error] Currency exchange failed: {exc}")
        return np.array([], dtype=float)


def suburb_summary(dataframe: pd.DataFrame, suburb: str) -> None:
    """
    Print summary statistics for bedrooms, bathrooms, and parking_spaces for a suburb.

    Args:
        dataframe: Input DataFrame.
        suburb: Target suburb name; use 'all' to include all suburbs.

    Returns:
        None
    """
    try:
        if not isinstance(dataframe, pd.DataFrame) or dataframe.empty:
            raise ValueError("dataframe is empty or invalid. Load data first.")
        if not isinstance(suburb, str) or not suburb.strip():
            raise ValueError("suburb must be a non-empty string.")

        suburb_key = suburb.strip()
        df_use = dataframe

        if suburb_key.lower() != "all":
            if "suburb" not in dataframe.columns:
                raise KeyError("dataframe must contain a 'suburb' column.")
            mask = dataframe["suburb"].astype(str).str.lower() == suburb_key.lower()
            if not mask.any():
                print(f"[Error] Suburb not found: {suburb_key}.")
                return
            df_use = dataframe.loc[mask].copy()

        metrics = ["bedrooms", "bathrooms", "parking_spaces"]
        print("=" * 60)
        print(f"Suburb summary: {suburb_key}")
        print("=" * 60)
        for col in metrics:
            if col not in df_use.columns:
                print(f"[Warn] Missing column: {col}")
                continue
            series = pd.to_numeric(df_use[col], errors="coerce").dropna()
            if series.empty:
                print(f"{col}: No valid values.")
                continue

            mean_v = series.mean()
            std_v = series.std()
            med_v = series.median()
            min_v = series.min()
            max_v = series.max()

            print(f"\n{col}:")
            print(f"  mean   : {mean_v:.2f}")
            print(f"  std    : {std_v:.2f}")
            print(f"  median : {med_v:.2f}")
            print(f"  min    : {min_v:.2f}")
            print(f"  max    : {max_v:.2f}")
        print("")
    except Exception as exc:
        print(f"[Error] suburb_summary failed: {exc}")


def _land_size_to_m2(land_size: float, land_unit: str) -> Optional[float]:
    """Convert land size to square meters. Returns None if invalid/unknown."""
    if land_size is None or np.isnan(land_size):
        return None
    if land_size <= 0:
        return None
    unit = (land_unit or "").strip().lower()

    # Known units from dataset/spec: 'm²', 'm2', 'sqm', 'ha'
    if unit in {"m²", "m2", "sqm", "square meters", "square metres"} or unit == "":
        return float(land_size)
    if unit in {"ha", "hectare", "hectares"}:
        return float(land_size) * 10000.0
    return None


def avg_land_size(dataframe: pd.DataFrame, suburb: str) -> Optional[float]:
    """
    Calculate and return the average land size (in m^2) of properties in a suburb.

    Args:
        dataframe: Input DataFrame.
        suburb: Target suburb name; use 'all' for all suburbs.

    Returns:
        Average land size in square meters (float) or None if suburb invalid/no data.
    """
    try:
        if not isinstance(dataframe, pd.DataFrame) or dataframe.empty:
            raise ValueError("dataframe is empty or invalid. Load data first.")
        if not isinstance(suburb, str) or not suburb.strip():
            raise ValueError("suburb must be a non-empty string.")

        suburb_key = suburb.strip()
        df_use = dataframe
        if suburb_key.lower() != "all":
            if "suburb" not in dataframe.columns:
                raise KeyError("dataframe must contain a 'suburb' column.")
            mask = dataframe["suburb"].astype(str).str.lower() == suburb_key.lower()
            if not mask.any():
                print(f"[Error] Suburb not found: {suburb_key}.")
                return None
            df_use = dataframe.loc[mask].copy()

        if "land_size" not in df_use.columns:
            raise KeyError("dataframe must contain a 'land_size' column.")

        land = pd.to_numeric(df_use["land_size"], errors="coerce")
        units = df_use["land_size_unit"] if "land_size_unit" in df_use.columns else ""

        m2_vals: List[float] = []
        if "land_size_unit" in df_use.columns:
            for val, unit in zip(land.to_numpy(), units.astype(str).to_numpy()):
                conv = _land_size_to_m2(val, unit)
                if conv is not None:
                    m2_vals.append(conv)
        else:
            # assume m2 if unit column missing
            for val in land.to_numpy():
                conv = _land_size_to_m2(val, "m2")
                if conv is not None:
                    m2_vals.append(conv)

        if not m2_vals:
            return None
        return float(np.mean(m2_vals))
    except Exception as exc:
        print(f"[Error] avg_land_size failed: {exc}")
        return None


def _reverse_insertion_sort_desc(values: List[float]) -> List[float]:
    """Reverse insertion sort in descending order (in-place algorithm)."""
    # Copy to avoid mutating caller
    arr = list(values)
    for i in range(1, len(arr)):
        key = arr[i]
        j = i - 1
        # Descending: move smaller elements right
        while j >= 0 and arr[j] < key:
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = key
    return arr


def _binary_search_desc_recursive(arr: List[float], target: float, left: int, right: int) -> bool:
    """Recursive binary search on a list sorted in descending order."""
    if left > right:
        return False
    mid = (left + right) // 2
    mid_val = arr[mid]

    if mid_val == target:
        return True
    if mid_val < target:
        # target is bigger; go left (since descending)
        return _binary_search_desc_recursive(arr, target, left, mid - 1)
    # mid_val > target
    return _binary_search_desc_recursive(arr, target, mid + 1, right)


def locate_price(target_price: float, data: pd.DataFrame, target_suburb: str) -> bool:
    """
    Determine if a specific price exists in the list of prices for a specific suburb.

    Steps (required):
    1) Filter prices by target_suburb
    2) Sort prices using reverse insertion sort (descending)
    3) Search for target_price using recursive binary search

    Args:
        target_price: Numeric target price value.
        data: A DataFrame (loaded previously).
        target_suburb: Suburb to filter.

    Returns:
        True if found, else False.
    """
    try:
        if not isinstance(data, pd.DataFrame) or data.empty:
            raise ValueError("data is empty or invalid. Load data first.")
        if not isinstance(target_suburb, str) or not target_suburb.strip():
            raise ValueError("target_suburb must be a non-empty string.")
        if not isinstance(target_price, (int, float)) or np.isnan(float(target_price)):
            raise ValueError("target_price must be a numeric value.")

        suburb_key = target_suburb.strip()
        if "suburb" not in data.columns or "price" not in data.columns:
            raise KeyError("data must contain 'suburb' and 'price' columns.")

        mask = data["suburb"].astype(str).str.lower() == suburb_key.lower()
        if not mask.any():
            print(f"[Error] Suburb not found: {suburb_key}.")
            return False

        prices = pd.to_numeric(data.loc[mask, "price"], errors="coerce").dropna().to_list()
        if not prices:
            return False

        sorted_prices = _reverse_insertion_sort_desc(prices)
        return _binary_search_desc_recursive(sorted_prices, float(target_price), 0, len(sorted_prices) - 1)
    except Exception as exc:
        print(f"[Error] locate_price failed: {exc}")
        return False


class SimpleDataAnalyser:
    """OOP wrapper around the required functions."""

    def extract_property_info(self, file_path: str) -> pd.DataFrame:
        return extract_property_info(file_path)

    def currency_exchange(self, dataframe: pd.DataFrame, exchange_rate: float) -> np.ndarray:
        return currency_exchange(dataframe, exchange_rate)

    def suburb_summary(self, dataframe: pd.DataFrame, suburb: str) -> None:
        suburb_summary(dataframe, suburb)

    def avg_land_size(self, dataframe: pd.DataFrame, suburb: str) -> Optional[float]:
        return avg_land_size(dataframe, suburb)

    def locate_price(self, target_price: float, data: pd.DataFrame, target_suburb: str) -> bool:
        return locate_price(target_price, data, target_suburb)

