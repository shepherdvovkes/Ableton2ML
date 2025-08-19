#!/usr/bin/env python3
"""
Simplified test server for HF_TOKEN integration
"""

import os
import json
import logging
from datetime import datetime
from dotenv import load_dotenv
from flask import Flask, jsonify
from flask_cors import CORS
import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load environment variables from ~/.env
load_dotenv(os.path.expanduser('~/.env'))

app = Flask(__name__)
CORS(app)

# Get HF_TOKEN from environment
hf_token = os.getenv('HF_TOKEN')
if not hf_token:
    logger.warning("HF_TOKEN not found in environment variables")
else:
    logger.info("HF_TOKEN loaded successfully")

@app.route('/api/status', methods=['GET'])
def get_status():
    """Get server status"""
    return jsonify({
        'status': 'running',
        'timestamp': datetime.now().isoformat(),
        'hf_token_loaded': bool(hf_token),
        'server_type': 'test_server'
    })

@app.route('/api/hf/status', methods=['GET'])
def get_hf_status():
    """Get Hugging Face token status and test connection"""
    try:
        if not hf_token:
            return jsonify({
                'status': 'error',
                'message': 'HF_TOKEN not configured',
                'token_available': False
            }), 400
        
        # Test HF token by making a simple API call to models endpoint
        headers = {'Authorization': f'Bearer {hf_token}'}
        response = requests.get('https://huggingface.co/api/models?search=music&limit=1', headers=headers)
        
        if response.status_code == 200:
            models = response.json()
            return jsonify({
                'status': 'success',
                'token_available': True,
                'models_found': len(models),
                'message': 'HF_TOKEN is valid and working for model access',
                'note': 'Token has read access to models (may be read-only)'
            })
        else:
            return jsonify({
                'status': 'error',
                'token_available': True,
                'message': f'HF_TOKEN validation failed: {response.status_code}',
                'error': response.text
            }), 400
            
    except Exception as e:
        logger.error(f"Error checking HF status: {e}")
        return jsonify({
            'status': 'error',
            'token_available': bool(hf_token),
            'message': f'Error checking HF status: {str(e)}'
        }), 500

@app.route('/api/hf/models', methods=['GET'])
def get_hf_models():
    """Get available Hugging Face models"""
    try:
        if not hf_token:
            return jsonify({
                'status': 'error',
                'message': 'HF_TOKEN not configured',
                'token_available': False
            }), 400
        
        # Search for music generation models
        headers = {'Authorization': f'Bearer {hf_token}'}
        params = {
            'search': 'music generation',
            'limit': 10,
            'full': 'false'
        }
        response = requests.get('https://huggingface.co/api/models', headers=headers, params=params)
        
        if response.status_code == 200:
            models = response.json()
            return jsonify({
                'status': 'success',
                'models': models,
                'count': len(models)
            })
        else:
            return jsonify({
                'status': 'error',
                'message': f'Failed to fetch models: {response.status_code}',
                'error': response.text
            }), 400
            
    except Exception as e:
        logger.error(f"Error fetching HF models: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Error fetching HF models: {str(e)}'
        }), 500

@app.route('/api/magenta/models', methods=['GET'])
def get_magenta_models():
    """Get information about Google Magenta models"""
    try:
        # List of common Magenta models
        magenta_models = {
            'music_vae': {
                'name': 'MusicVAE',
                'description': 'Variational autoencoder for music generation',
                'configs': [
                    'cat-mel_2bar_big',
                    'cat-mel_2bar_small',
                    'hierdec-mel_16bar',
                    'hierdec-trio_16bar'
                ],
                'capabilities': ['variation', 'interpolation', 'latent space exploration']
            },
            'music_transformer': {
                'name': 'Music Transformer',
                'description': 'Transformer model for music generation',
                'configs': [
                    'transformer_autoencoder',
                    'transformer_autoencoder_relative',
                    'transformer_autoencoder_relative_attention'
                ],
                'capabilities': ['continuation', 'generation', 'style transfer']
            },
            'melody_rnn': {
                'name': 'MelodyRNN',
                'description': 'Recurrent neural network for melody generation',
                'configs': [
                    'basic_rnn',
                    'lookback_rnn',
                    'attention_rnn'
                ],
                'capabilities': ['melody generation', 'continuation']
            },
            'improv_rnn': {
                'name': 'ImprovRNN',
                'description': 'RNN for jazz improvisation',
                'configs': [
                    'chord_pitches_improv',
                    'melody_chord_pitches_improv'
                ],
                'capabilities': ['jazz improvisation', 'chord accompaniment']
            }
        }
        
        return jsonify({
            'status': 'success',
            'models': magenta_models,
            'note': 'These are the standard Google Magenta models. Checkpoint files need to be downloaded separately.'
        })
        
    except Exception as e:
        logger.error(f"Error getting Magenta models: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Error getting Magenta models: {str(e)}'
        }), 500

if __name__ == '__main__':
    logger.info("Starting test server...")
    logger.info(f"HF_TOKEN loaded: {bool(hf_token)}")
    app.run(host='0.0.0.0', port=5001, debug=True)
