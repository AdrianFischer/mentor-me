"""
Nano Banana Pro - Gemini Image Generation Script

This script generates images using Google's Gemini 2.5 Flash Image model.

SETUP REQUIREMENTS:
===================

1. Install required Python packages:
   - google-genai (NOT google-generativeai - these are different packages!)
   - Pillow (for image handling)
   
   Run: pip install google-genai pillow

2. Set environment variable:
   export GEMINI_API_KEY="your-api-key-here"
   
   Or create a .env file in the project root with:
   GEMINI_API_KEY=your-api-key-here

3. Verify setup:
   Run: python3 scripts/setup_nano_banana_pro.py

USAGE:
======

As a command-line script:
  python3 scripts/nano_banana.py "a futuristic cityscape at sunset"
  python3 scripts/nano_banana.py "a diagram showing data flow" --output custom_name.png

As a Python module:
  from scripts.nano_banana import generate_image
  image_path = generate_image("a beautiful landscape", output_path="landscape.png")

TROUBLESHOOTING:
================

- If you get "ModuleNotFoundError: No module named 'google.genai'":
  → You need to install google-genai (not google-generativeai)
  → Run: pip install google-genai

- If you get import errors with PIL:
  → Install Pillow: pip install pillow

- If you get "API key not found":
  → Set GEMINI_API_KEY environment variable
  → Or pass it via --api-key flag

NOTE: This script requires the 'google-genai' package, which is different from
'google-generativeai'. The google-genai package provides the newer Client API.
"""

import os
import sys
import argparse
from pathlib import Path
from typing import Optional

try:
    from dotenv import load_dotenv
    load_dotenv()  # Load environment variables from .env file
except ImportError:
    pass  # python-dotenv not installed, ignoring .env file

try:
    from google.genai import Client  # install via: pip install google-genai
    from google.genai import types
    from PIL import Image
except ImportError as e:
    print(f"ERROR: Missing required package. {e}")
    print("Install with: pip install google-genai pillow")
    sys.exit(1)


def generate_image(
    prompt: str,
    api_key: Optional[str] = None,
    output_path: str = "output.png",
    model: str = "gemini-3-pro-image-preview",
    enable_search: bool = True,
    verbose: bool = True
) -> str:
    """
    Generate an image using Gemini API.
    
    Args:
        prompt: The text prompt describing the image to generate
        api_key: Gemini API key (defaults to GEMINI_API_KEY env var)
        output_path: Path where the image will be saved
        model: Gemini model to use
        enable_search: Whether to enable Google Search tool
        verbose: Whether to print status messages
        
    Returns:
        Path to the saved image file
        
    Raises:
        ValueError: If API key is not provided
        Exception: If image generation fails
    """
    # Get API key from parameter, environment variable, or error
    api_key = api_key or os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError(
            "API key not found. Set GEMINI_API_KEY environment variable "
            "or pass --api-key argument."
        )
    
    if verbose:
        print(f"Generating image with prompt: '{prompt}'")
        print(f"Output will be saved to: {output_path}")
    
    try:
        # Initialize client
        client = Client(api_key=api_key)
        
        # Create chat with image generation capabilities
        config = types.GenerateContentConfig(
            response_modalities=['TEXT', 'IMAGE'],
        )
        if enable_search:
            config.tools = [{"google_search": {}}]
        
        chat = client.chats.create(
            model=model,
            config=config
        )
        
        # Send message and get response
        response = chat.send_message(prompt)
        
        # Process response parts
        text_parts = []
        image_saved = False
        
        for part in response.parts:
            if part.text is not None:
                text_parts.append(part.text)
            elif image := part.as_image():
                # Ensure output directory exists
                output_file = Path(output_path)
                output_file.parent.mkdir(parents=True, exist_ok=True)
                
                # Save image
                image.save(str(output_file))
                image_saved = True
                if verbose:
                    print(f"✓ Image saved to: {output_file.absolute()}")
        
        # Print any text response
        if text_parts and verbose:
            print("\nText response:")
            print("\n".join(text_parts))
        
        if not image_saved:
            raise Exception("No image was generated in the response")
        
        return str(Path(output_path).absolute())
        
    except Exception as e:
        error_msg = f"Failed to generate image: {str(e)}"
        if verbose:
            print(f"ERROR: {error_msg}")
        raise Exception(error_msg) from e


def main():
    """Command-line interface for the image generation script."""
    parser = argparse.ArgumentParser(
        description="Generate images using Google's Gemini API",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s "a futuristic cityscape"
  %(prog)s "diagram of system architecture" --output diagrams/arch.png
  %(prog)s "logo design" --no-search
        """
    )
    
    parser.add_argument(
        "prompt",
        nargs="?",
        default=None,
        help="Text prompt describing the image to generate"
    )
    
    parser.add_argument(
        "--output", "-o",
        default="output.png",
        help="Output file path (default: output.png)"
    )
    
    parser.add_argument(
        "--api-key",
        default=None,
        help="Gemini API key (defaults to GEMINI_API_KEY env var)"
    )
    
    parser.add_argument(
        "--model",
        default="gemini-3-pro-image-preview",
        help="Gemini model to use (default: gemini-3-pro-image-preview)"
    )
    
    parser.add_argument(
        "--no-search",
        action="store_true",
        help="Disable Google Search tool"
    )
    
    parser.add_argument(
        "--quiet", "-q",
        action="store_true",
        help="Suppress status messages"
    )
    
    args = parser.parse_args()
    
    # If no prompt provided, check if we're being called interactively
    if not args.prompt:
        print("Enter your image generation prompt (or press Ctrl+C to cancel):")
        try:
            args.prompt = input("Prompt: ").strip()
            if not args.prompt:
                print("No prompt provided. Exiting.")
                sys.exit(1)
        except (KeyboardInterrupt, EOFError):
            print("\nCancelled.")
            sys.exit(0)
    
    try:
        output_path = generate_image(
            prompt=args.prompt,
            api_key=args.api_key,
            output_path=args.output,
            model=args.model,
            enable_search=not args.no_search,
            verbose=not args.quiet
        )
        if not args.quiet:
            print(f"\n✓ Success! Image saved to: {output_path}")
        sys.exit(0)
    except Exception as e:
        print(f"\n✗ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
