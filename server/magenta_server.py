#!/usr/bin/env python3
"""
Google Magenta Server for Ableton2ML
Provides REST API for MIDI generation using MusicVAE and Music Transformer
"""

import os
import json
import base64
import logging
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables from ~/.env
load_dotenv(os.path.expanduser('~/.env'))

import numpy as np
import tensorflow as tf
from flask import Flask, request, jsonify
from flask_cors import CORS
import pretty_midi
import mido

# Magenta imports
from magenta.models.music_vae import configs
from magenta.models.music_vae.trained_model import TrainedModel
from magenta.models.music_transformer import music_transformer
from magenta.models.music_transformer import melody_transformer
from magenta.models.shared import sequence_generator_bundle
from magenta.protobuf import music_pb2

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class MagentaServer:
    """Main server class for Google Magenta integration"""
    
    def __init__(self):
        self.app = Flask(__name__)
        CORS(self.app)
        
        # Get HF_TOKEN from environment
        self.hf_token = os.getenv('HF_TOKEN')
        if not self.hf_token:
            logger.warning("HF_TOKEN not found in environment variables")
        else:
            logger.info("HF_TOKEN loaded successfully")
        
        # Initialize models
        self.music_vae_model = None
        self.music_transformer_model = None
        self.models_loaded = False
        
        # Load models
        self.load_models()
        
        # Setup routes
        self.setup_routes()
    
    def load_models(self):
        """Load Google Magenta models"""
        try:
            logger.info("Loading Google Magenta models...")
            
            # Load MusicVAE model for variations
            self.music_vae_model = TrainedModel(
                configs.CONFIG_MAP['cat-mel_2bar_big'],
                batch_size=4,
                checkpoint_dir_or_path='cat-mel_2bar_big.ckpt'
            )
            
            # Load Music Transformer model for continuation
            bundle = sequence_generator_bundle.read_bundle_file(
                'transformer_autoencoder.mag'
            )
            self.music_transformer_model = music_transformer.MusicTransformer(
                model=bundle,
                details=bundle.generator_details,
                steps_per_quarter=4
            )
            
            self.models_loaded = True
            logger.info("Models loaded successfully")
            
        except Exception as e:
            logger.error(f"Error loading models: {e}")
            self.models_loaded = False
    
    def setup_routes(self):
        """Setup Flask routes"""
        
        @self.app.route('/api/status', methods=['GET'])
        def get_status():
            """Get server status"""
            return jsonify({
                'status': 'running',
                'models_loaded': self.models_loaded,
                'timestamp': datetime.now().isoformat(),
                'gpu_available': tf.config.list_physical_devices('GPU'),
                'hf_token_loaded': bool(self.hf_token)
            })
        
        @self.app.route('/api/models', methods=['GET'])
        def get_models():
            """Get available models"""
            return jsonify({
                'models': {
                    'music_vae': 'cat-mel_2bar_big',
                    'music_transformer': 'transformer_autoencoder'
                },
                'capabilities': {
                    'variation': 'Generate variations of MIDI sequences',
                    'continuation': 'Continue MIDI sequences',
                    'new_track': 'Generate new tracks based on context'
                }
            })
        
        @self.app.route('/api/generate/variation', methods=['POST'])
        def generate_variation():
            """Generate variations of MIDI sequence"""
            try:
                data = request.get_json()
                midi_data = data.get('midi_data')
                num_variations = data.get('num_variations', 3)
                creativity_level = data.get('creativity_level', 0.8)
                style_preset = data.get('style_preset', 'electronic')
                
                if not midi_data:
                    return jsonify({'error': 'No MIDI data provided'}), 400
                
                # Decode MIDI data
                midi_bytes = base64.b64decode(midi_data)
                
                # Generate variations
                variations = self.generate_music_vae_variations(
                    midi_bytes, num_variations, creativity_level
                )
                
                return jsonify({
                    'status': 'success',
                    'variations': variations,
                    'generation_params': {
                        'num_variations': num_variations,
                        'creativity_level': creativity_level,
                        'style_preset': style_preset
                    }
                })
                
            except Exception as e:
                logger.error(f"Error generating variation: {e}")
                return jsonify({'error': str(e)}), 500
        
        @self.app.route('/api/generate/continuation', methods=['POST'])
        def generate_continuation():
            """Continue MIDI sequence"""
            try:
                data = request.get_json()
                midi_data = data.get('midi_data')
                target_length = data.get('target_length', 16)
                target_instrument = data.get('target_instrument', 'piano')
                style_preset = data.get('style_preset', 'jazz')
                
                if not midi_data:
                    return jsonify({'error': 'No MIDI data provided'}), 400
                
                # Decode MIDI data
                midi_bytes = base64.b64decode(midi_data)
                
                # Generate continuation
                continuation = self.generate_music_transformer_continuation(
                    midi_bytes, target_length, target_instrument
                )
                
                return jsonify({
                    'status': 'success',
                    'continuation': continuation,
                    'generation_params': {
                        'target_length': target_length,
                        'target_instrument': target_instrument,
                        'style_preset': style_preset
                    }
                })
                
            except Exception as e:
                logger.error(f"Error generating continuation: {e}")
                return jsonify({'error': str(e)}), 500
        
        @self.app.route('/api/generate/new_track', methods=['POST'])
        def generate_new_track():
            """Generate new track based on context"""
            try:
                data = request.get_json()
                context_tracks = data.get('context_tracks', [])
                target_instrument = data.get('target_instrument', 'lead_synth')
                style_preset = data.get('style_preset', 'pop')
                track_length = data.get('track_length', 32)
                
                if not context_tracks:
                    return jsonify({'error': 'No context tracks provided'}), 400
                
                # Generate new track
                new_track = self.generate_new_track_from_context(
                    context_tracks, target_instrument, track_length
                )
                
                return jsonify({
                    'status': 'success',
                    'new_track': new_track,
                    'generation_params': {
                        'target_instrument': target_instrument,
                        'style_preset': style_preset,
                        'track_length': track_length
                    }
                })
                
            except Exception as e:
                logger.error(f"Error generating new track: {e}")
                return jsonify({'error': str(e)}), 500
        
        @self.app.route('/api/hf/status', methods=['GET'])
        def get_hf_status():
            """Get Hugging Face token status and test connection"""
            try:
                if not self.hf_token:
                    return jsonify({
                        'status': 'error',
                        'message': 'HF_TOKEN not configured',
                        'token_available': False
                    }), 400
                
                # Test HF token by making a simple API call
                import requests
                headers = {'Authorization': f'Bearer {self.hf_token}'}
                response = requests.get('https://huggingface.co/api/whoami', headers=headers)
                
                if response.status_code == 200:
                    user_info = response.json()
                    return jsonify({
                        'status': 'success',
                        'token_available': True,
                        'user_info': user_info,
                        'message': 'HF_TOKEN is valid and working'
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
                    'token_available': bool(self.hf_token),
                    'message': f'Error checking HF status: {str(e)}'
                }), 500
    
    def generate_music_vae_variations(
        self, 
        midi_bytes: bytes, 
        num_variations: int, 
        creativity_level: float
    ) -> List[Dict]:
        """Generate variations using MusicVAE"""
        try:
            # Convert MIDI to NoteSequence
            midi_file = pretty_midi.PrettyMIDI(midi_bytes)
            note_sequence = midi_file.to_sequence()
            
            # Generate variations
            variations = []
            for i in range(num_variations):
                # Set temperature based on creativity level
                temperature = 0.5 + (creativity_level * 0.5)
                
                # Generate variation
                generated_sequence = self.music_vae_model.interpolate(
                    [note_sequence], 
                    length=num_variations,
                    temperature=temperature
                )[i]
                
                # Convert back to MIDI
                midi_data = self.sequence_to_midi(generated_sequence)
                midi_base64 = base64.b64encode(midi_data).decode('utf-8')
                
                variations.append({
                    'midi_data': midi_base64,
                    'variation_id': i + 1,
                    'temperature': temperature
                })
            
            return variations
            
        except Exception as e:
            logger.error(f"Error in MusicVAE generation: {e}")
            raise
    
    def generate_music_transformer_continuation(
        self, 
        midi_bytes: bytes, 
        target_length: int, 
        target_instrument: str
    ) -> Dict:
        """Generate continuation using Music Transformer"""
        try:
            # Convert MIDI to NoteSequence
            midi_file = pretty_midi.PrettyMIDI(midi_bytes)
            note_sequence = midi_file.to_sequence()
            
            # Generate continuation
            generated_sequence = self.music_transformer_model.generate(
                note_sequence,
                target_length,
                temperature=0.8
            )
            
            # Convert back to MIDI
            midi_data = self.sequence_to_midi(generated_sequence)
            midi_base64 = base64.b64encode(midi_data).decode('utf-8')
            
            return {
                'midi_data': midi_base64,
                'target_length': target_length,
                'target_instrument': target_instrument
            }
            
        except Exception as e:
            logger.error(f"Error in Music Transformer generation: {e}")
            raise
    
    def generate_new_track_from_context(
        self, 
        context_tracks: List[Dict], 
        target_instrument: str, 
        track_length: int
    ) -> Dict:
        """Generate new track based on context tracks"""
        try:
            # Combine context tracks
            combined_sequence = music_pb2.NoteSequence()
            
            for track in context_tracks:
                midi_bytes = base64.b64decode(track['midi_data'])
                midi_file = pretty_midi.PrettyMIDI(midi_bytes)
                track_sequence = midi_file.to_sequence()
                
                # Merge tracks
                for note in track_sequence.notes:
                    combined_sequence.notes.add().CopyFrom(note)
            
            # Generate new track using Music Transformer
            generated_sequence = self.music_transformer_model.generate(
                combined_sequence,
                track_length,
                temperature=0.7
            )
            
            # Convert back to MIDI
            midi_data = self.sequence_to_midi(generated_sequence)
            midi_base64 = base64.b64encode(midi_data).decode('utf-8')
            
            return {
                'midi_data': midi_base64,
                'target_instrument': target_instrument,
                'track_length': track_length
            }
            
        except Exception as e:
            logger.error(f"Error generating new track: {e}")
            raise
    
    def sequence_to_midi(self, sequence: music_pb2.NoteSequence) -> bytes:
        """Convert NoteSequence to MIDI bytes"""
        try:
            # Convert to PrettyMIDI
            midi_file = pretty_midi.PrettyMIDI()
            
            # Add notes
            for note in sequence.notes:
                midi_file.notes.append(pretty_midi.Note(
                    velocity=note.velocity,
                    pitch=note.pitch,
                    start=note.start_time,
                    end=note.end_time
                ))
            
            # Convert to bytes
            midi_bytes = midi_file.write()
            return midi_bytes
            
        except Exception as e:
            logger.error(f"Error converting sequence to MIDI: {e}")
            raise
    
    def run(self, host='0.0.0.0', port=5001, debug=False):
        """Run the Flask server"""
        logger.info(f"Starting Magenta server on {host}:{port}")
        self.app.run(host=host, port=port, debug=debug)

if __name__ == '__main__':
    server = MagentaServer()
    server.run(debug=True)
