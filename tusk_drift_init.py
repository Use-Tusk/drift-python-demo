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
    api_key=os.environ.get("tusk-1e287605ae3141c351cce108a8e9226d"),
    env="local"
)
