import unittest
import tempfile
import os
from app import app, get_db_connection

class ScratchPadTestCase(unittest.TestCase):

    def setUp(self):
        self.db_fd, app.config['DATABASE'] = tempfile.mkstemp()
        app.config['TESTING'] = True
        self.app = app.test_client()
        
        with app.app_context():
            conn = get_db_connection()
            with open('schema.sql', 'r') as f:
                conn.executescript(f.read())
            conn.close()

    def tearDown(self):
        os.close(self.db_fd)
        os.unlink(app.config['DATABASE'])

    def test_index_page(self):
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'My Scratch Pad', response.data)

    def test_create_post(self):
        response = self.app.post('/create', data={
            'title': 'Test Post',
            'content': 'This is a test post content'
        }, follow_redirects=True)
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Test Post', response.data)

    def test_create_post_missing_title(self):
        response = self.app.post('/create', data={
            'title': '',
            'content': 'This is a test post content'
        })
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Title is required!', response.data)

    def test_health_check(self):
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)

if __name__ == '__main__':
    unittest.main()