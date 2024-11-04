# API - Flutter Project
# Authors: Guilherme Antunes [103600], Pedro Rasinhas [103541]

## Description
This is the API that BusTracker and BusTracker Validator will consume during its execution.

## Requirements
- Python

## Installation

Create a virtual environment

```bat
py -3.13 -m venv venv
```
Activate the virtual environment

```bat
.\venv\Scripts\activate
```
Install the requirements

```bat
pip install -r .\requirements.txt
```


## Running the Application
```bat
.\start.bat
```
or

```bash
fastapi dev .\main.py "--host" "0.0.0.0" --reload
```