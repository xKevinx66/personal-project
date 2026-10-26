# ------------------------------------------------------------
# Property Investment Management System
# Author: xKevinx66
# ------------------------------------------------------------
"""
investor.py

Text-based interface (menu) for the Property Investment Management System.
"""

from __future__ import annotations

import os
from typing import Optional

import pandas as pd

from simple_data_analyser import SimpleDataAnalyser
from data_visualiser import DataVisualiser


class Investor:
    """Main application class for menu interaction."""

    def __init__(self) -> None:
        self.data_analyser = SimpleDataAnalyser()
        self.visualiser = DataVisualiser()
        self.dataframe: Optional[pd.DataFrame] = None

    @staticmethod
    def _print_menu() -> None:
        print("\n" + "=" * 28)
        print(" Property Investor Menu")
        print("=" * 28)
        print("1. Load property data (CSV)")
        print("2. Currency exchange (AUD -> target)")
        print("3. Suburb property summary")
        print("4. Average land size (m^2)")
        print("5. Property value distribution (histogram)")
        print("6. Sales trend (line chart)")
        print("7. Locate a target price (sort + recursive binary search)")
        print("0. Exit")

    @staticmethod
    def _prompt(prompt: str) -> str:
        return input(prompt).strip()

    @staticmethod
    def _prompt_float(prompt: str) -> Optional[float]:
        raw = input(prompt).strip()
        try:
            return float(raw)
        except Exception:
            print("[Error] Please input a numeric value.")
            return None

    def _require_df(self) -> bool:
        if self.dataframe is None or self.dataframe.empty:
            print("[Error] Data not loaded. Choose option 1 first.")
            return False
        return True

    def load_data(self) -> None:
        default_path = os.path.join(os.getcwd(), "property_information.csv")
        raw = self._prompt(f"Enter CSV path (default: {default_path}): ")
        path = raw if raw else default_path
        df = self.data_analyser.extract_property_info(path)
        if df is None or df.empty:
            print("[Error] Failed to load data.")
            return
        self.dataframe = df
        print(f"[OK] Loaded rows: {len(df)}  columns: {len(df.columns)}")

    def do_currency_exchange(self) -> None:
        if not self._require_df():
            return
        rate = self._prompt_float("Enter exchange rate (target per 1 AUD, e.g., 0.66 for USD): ")
        if rate is None or rate <= 0:
            print("[Error] Exchange rate must be positive.")
            return
        arr = self.data_analyser.currency_exchange(self.dataframe, rate)
        if arr.size == 0:
            print("[Error] No converted values.")
            return
        print(f"[OK] Converted price array length: {arr.size}")
        print("First 5 converted values:", arr[:5])

    def do_suburb_summary(self) -> None:
        if not self._require_df():
            return
        suburb = self._prompt('Enter suburb name (or "all"): ')
        if not suburb:
            print("[Error] suburb cannot be empty.")
            return
        self.data_analyser.suburb_summary(self.dataframe, suburb)

    def do_avg_land_size(self) -> None:
        if not self._require_df():
            return
        suburb = self._prompt('Enter suburb name (or "all"): ')
        if not suburb:
            print("[Error] suburb cannot be empty.")
            return
        result = self.data_analyser.avg_land_size(self.dataframe, suburb)
        if result is None:
            print("[Warn] No valid land size data for this suburb.")
        else:
            print(f"[OK] Average land size (m^2): {result:.2f}")

    def do_prop_val_distribution(self) -> None:
        if not self._require_df():
            return
        suburb = self._prompt('Enter suburb name (or "all"): ')
        if not suburb:
            print("[Error] suburb cannot be empty.")
            return
        currency = self._prompt('Enter target currency code (default "AUD"): ')
        currency = currency if currency else "AUD"
        self.visualiser.prop_val_distribution(self.dataframe, suburb, currency)

    def do_sales_trend(self) -> None:
        if not self._require_df():
            return
        self.visualiser.sales_trend(self.dataframe)

    def do_locate_price(self) -> None:
        if not self._require_df():
            return
        suburb = self._prompt("Enter target suburb: ")
        if not suburb:
            print("[Error] suburb cannot be empty.")
            return
        price = self._prompt_float("Enter target price (numeric): ")
        if price is None:
            return
        found = self.data_analyser.locate_price(price, self.dataframe, suburb)
        print(f"[OK] Found={found}")

    def run(self) -> None:
        """Start menu loop."""
        while True:
            self._print_menu()
            choice = self._prompt("Select an option: ")
            if choice == "1":
                self.load_data()
            elif choice == "2":
                self.do_currency_exchange()
            elif choice == "3":
                self.do_suburb_summary()
            elif choice == "4":
                self.do_avg_land_size()
            elif choice == "5":
                self.do_prop_val_distribution()
            elif choice == "6":
                self.do_sales_trend()
            elif choice == "7":
                self.do_locate_price()
            elif choice == "0":
                print("Bye.")
                break
            else:
                print("[Error] Invalid choice. Please try again.")

