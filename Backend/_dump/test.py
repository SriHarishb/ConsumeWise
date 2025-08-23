import ollama

def send_image_to_gemma(model_name: str, image_path: str, prompt: str):
    """
    Send an image along with a prompt to the Gemma 3 model via Ollama.

    Args:
        model_name (str): e.g., 'gemma3:4b'
        image_path (str): Path to the image file
        prompt (str): Instruction for the model
    
    Returns:
        str: The response content
    """
    # Send the chat request including an image
    response_stream = ollama.chat(
        model=model_name,
        messages=[{
            "role": "user",
            "content": prompt,
            "images": [image_path]  # can also be bytes or file-like objects
        }],
        stream=True
    )
    # Collect all streamed chunks
    
    for chunk in response_stream:
        print(chunk["message"]["content"],end="")


if __name__ == "__main__":
    # Ensure Ollama (v0.6+) is installed, model is downloaded, and available locally
    # Example setup:
    # pip install ollama
    # import ollama; ollama.pull('gemma3:4b')
    
    model = "gemma3"
    img_path = "C:\\Users\\admin\\Pictures\\saajidpongal3.jpg"
    prompt = "Describe what you see in this image."
    send_image_to_gemma(model, img_path, prompt)
