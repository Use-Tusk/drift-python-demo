"""
Tusk Drift SDK initialization module.

This module initializes the Tusk Drift SDK for recording and replaying API traffic.
"""

from drift import TuskDrift

# Initialize Tusk Drift SDK
tusk_drift = TuskDrift.initialize(env="local")
