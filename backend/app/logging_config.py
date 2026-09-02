"""Application logging configuration."""

import logging


def configure_logging() -> None:
    """Configure consistent console logging for the API process."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )