# Vehicle Rental System

A menu-driven C++ project that models cars and motorcycles and supports vehicle inventory and rental operations.

## Features

- Abstract `Vehicle` base class with `Car` and `Motorcycle` subclasses.
- Virtual functions and runtime polymorphism for display and rental-cost calculation.
- Template-based vehicle manager using STL containers.
- Add, search, update, rent, return, list, and summarise vehicles.
- Save records to and load records from a text file.
- Input validation and separate Windows/Linux terminal clearing behaviour.

## Build

With a C++17-compatible compiler:

```bash
g++ -std=c++17 -O2 -Wall -Wextra vehicle_rental_system.cpp -o vehicle_rental_system
```

## Run

Linux/macOS:

```bash
./vehicle_rental_system
```

Windows PowerShell:

```powershell
.\vehicle_rental_system.exe
```

The program prompts for a text filename when saving or loading vehicle records.

