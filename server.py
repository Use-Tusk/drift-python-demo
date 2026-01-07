from tusk_drift_init import tusk_drift
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)
PORT = 3000


def convert_celsius_to_fahrenheit(celsius):
    return (celsius * 9/5) + 32


@app.route('/api/weather-activity', methods=['GET'])
def weather_activity():
    """Get location from IP, weather, and activity recommendations"""
    try:
        # First API call: Get user's location from IP
        location_response = requests.get('http://ip-api.com/json/')
        location_response.raise_for_status()
        location_data = location_response.json()
        city = location_data['city']
        lat = location_data['lat']
        lon = location_data['lon']
        country = location_data['country']

        # Business logic: Determine activity based on location
        is_coastal = abs(lon) > 50 or abs(lat) < 30

        # Second API call: Get weather for the location
        weather_response = requests.get(
            f'https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true'
        )
        weather_response.raise_for_status()
        weather = weather_response.json()['current_weather']

        weather['temperature'] = convert_celsius_to_fahrenheit(weather['temperature'])

        # Business logic: Recommend activity based on weather
        recommended_activity = 'Play a board game'
        if weather['temperature'] > 40:
            recommended_activity = 'Too hot - stay indoors'
        elif weather['temperature'] > 20 and weather['windspeed'] < 20:
            recommended_activity = 'Beach day!' if is_coastal else 'Perfect for hiking!'
        elif weather['temperature'] < 10:
            recommended_activity = 'Hot chocolate weather'
        elif weather['windspeed'] > 30:
            recommended_activity = 'Too windy - indoor activities recommended'
        else:
            recommended_activity = 'Nice day for a walk'

        # Third API call: Get a random activity suggestion
        activity_response = requests.get('https://bored-api.appbrewery.com/random')
        activity_response.raise_for_status()
        alternative_activity = activity_response.json()

        return jsonify({
            'location': {
                'city': city,
                'country': country,
                'coordinates': {'lat': lat, 'lon': lon},
                'isCoastal': is_coastal
            },
            'weather': {
                'temperature': weather['temperature'],
                'windspeed': weather['windspeed'],
                'weathercode': weather['weathercode'],
                'time': weather['time']
            },
            'recommendations': {
                'weatherBased': recommended_activity,
                'alternative': {
                    'activity': alternative_activity['activity'],
                    'type': alternative_activity['type'],
                    'participants': alternative_activity['participants']
                }
            }
        })
    except Exception as error:
        return jsonify({'error': 'Failed to fetch weather and activity data'}), 500


@app.route('/api/user/<user_id>', methods=['GET'])
def get_user(user_id):
    """Get random user with seed parameter"""
    try:
        response = requests.get(f'https://randomuser.me/api/?seed={user_id}')
        response.raise_for_status()
        return jsonify(response.json())
    except Exception as error:
        return jsonify({'error': 'Failed to fetch user data'}), 500


@app.route('/api/user', methods=['POST'])
def create_user():
    """Create random user (no seed)"""
    try:
        response = requests.get('https://randomuser.me/api/')
        response.raise_for_status()
        return jsonify(response.json())
    except Exception as error:
        return jsonify({'error': 'Failed to create user'}), 500


def get_post_with_comments(post_id):
    post_response = requests.get(f'https://jsonplaceholder.typicode.com/posts/{post_id}')
    post_response.raise_for_status()
    return {'post': post_response.json(), 'comments': []}


@app.route('/api/post/<int:post_id>', methods=['GET'])
def get_post(post_id):
    """Get post with comments"""
    try:
        result = get_post_with_comments(post_id)
        return jsonify(result)
    except Exception as error:
        return jsonify({'error': 'Failed to fetch post data'}), 500


@app.route('/api/post', methods=['POST'])
def create_post():
    """Create new post"""
    try:
        data = request.get_json()
        title = data.get('title')
        body = data.get('body')
        user_id = data.get('userId')

        response = requests.post('https://jsonplaceholder.typicode.com/posts', json={
            'title': title,
            'body': body,
            'userId': user_id
        })
        response.raise_for_status()

        return jsonify(response.json()), 201
    except Exception as error:
        return jsonify({'error': 'Failed to create post'}), 500


@app.route('/api/post/<int:post_id>', methods=['DELETE'])
def delete_post(post_id):
    """Delete post"""
    try:
        response = requests.delete(f'https://jsonplaceholder.typicode.com/posts/{post_id}')
        response.raise_for_status()

        return jsonify({'message': f'Post {post_id} deleted successfully'})
    except Exception as error:
        return jsonify({'error': 'Failed to delete post'}), 500


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'})


def main():
    tusk_drift.mark_app_as_ready()
    print(f'Server is running on http://localhost:{PORT}')
    print('\nAvailable endpoints:')
    print('  GET /api/weather-activity     - Recommend activity based on location and weather')
    print('  GET /api/user/<id>             - Get user')
    print('  POST /api/user                - Create user')
    print('  GET /api/post/<id>             - Get post, with comments')
    print('  POST /api/post                - Create post')
    print('  DELETE /api/post/<id>          - Delete post')

    app.run(host='0.0.0.0', port=PORT)


if __name__ == '__main__':
    main()
