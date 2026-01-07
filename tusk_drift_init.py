"""
Tusk Drift SDK initialization module.

This module initializes the Tusk Drift SDK for recording and replaying API traffic.
"""

import os

from dotenv import load_dotenv
from drift import TuskDrift

load_dotenv()

# Initialize Tusk Drift SDK
tusk_drift = TuskDrift.initialize(
    api_key=os.environ.get("TUSK_API_KEY"),
    env="local"
)
