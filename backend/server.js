require('dotenv').config();
const express = require('express');
const cors = require('cors');
const db = require('./db');
const { upload, uploadToCloudinary } = require('./upload');
const app = express();

app.use(cors());
app.use(express.json());
app.use('/downloads', express.static('public/downloads'));

// Basic Route
app.get('/', (req, res) => {
    res.json({ message: 'Ladies Boutique API is running' });
});

app.get('/api/app-version', (req, res) => {
    res.json({
        version: "1.0.8",
        url: "https://ladies-boutique-backend.onrender.com/downloads/rkj-fashions.apk",
        forceUpdate: false,
        releaseNotes: "RKJ Fashions v1.0.8: Renamed App. Addressed Reviews, Notifications, Wishlist, and signup flow."
    });
});

app.get('/api/db-init', async (req, res) => {
    try {
        await db.initDb();
        res.json({ message: 'Database initialization attempted' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/debug/users', async (req, res) => {
    try {
        const result = await db.query('SELECT id, phone, email, name, role FROM users ORDER BY id');
        const users = result.rows.map(u => ({
            ...u,
            member_id: `RKJ${String(u.id).padStart(3, '0')}`
        }));
        res.json(users);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- UPLOAD ROUTE ---
app.post('/api/upload', upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No image file provided' });
        }

        const result = await uploadToCloudinary(req.file.buffer);
        res.json({
            url: result.secure_url,
            public_id: result.public_id
        });
    } catch (err) {
        console.error('Upload error:', err);
        res.status(500).json({ error: 'Failed to upload image' });
    }
});

// --- AUTH ROUTES ---
app.post('/api/auth/signup', async (req, res) => {
    const { identifier, password, name, phone: reqPhone, email: reqEmail } = req.body;

    // Determine Phone and Email
    let email = reqEmail || null;
    let phone = reqPhone || null;

    // Fallback: If explicit fields are missing, try to parse identifier
    if (!email && !phone && identifier) {
        if (identifier.includes('@')) {
            email = identifier;
        } else {
            phone = identifier;
        }
    }

    if (!email && !phone) {
        // If still nothing, error
        return res.status(400).json({ error: 'Phone or Email is required' });
    }

    try {
        // Check if user exists by email or phone
        const check = await db.query('SELECT * FROM users WHERE (email IS NOT NULL AND email = $1) OR (phone IS NOT NULL AND phone = $2)', [email, phone]);
        if (check.rows.length > 0) return res.status(400).json({ error: 'User already exists' });

        // Insert new user
        // TODO: Hash password with bcrypt before saving
        const result = await db.query(
            "INSERT INTO users (phone, password, name, email, role) VALUES ($1, $2, $3, $4, 'user') RETURNING *",
            [phone, password, name, email]
        );

        const user = result.rows[0];

        // MOCK JWT for now
        res.status(201).json({
            token: 'mock-jwt-token',
            user: {
                id: user.id,
                email: user.email,
                role: user.role,
                phone: user.phone,
                name: user.name,
                profile_image_url: user.profile_image_url
            }
        });
    } catch (err) {
        console.error('Signup error:', err);
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/auth/login', async (req, res) => {
    // Implement Login Logic (Phone or Email)
    const { password } = req.body;
    const loginId = req.body.identifier || req.body.phone || req.body.email;

    if (!loginId) {
        return res.status(400).json({ error: 'Email or Phone is required' });
    }

    try {
        console.log('Login attempt for:', loginId);
        // Check DB for either phone or email
        const result = await db.query('SELECT * FROM users WHERE TRIM(phone) = TRIM($1) OR TRIM(email) = TRIM($1)', [String(loginId).trim()]);

        console.log('Found users:', result.rows.length);
        if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });

        const user = result.rows[0];
        // TODO: Verify password with bcrypt
        // if (!await bcrypt.compare(password, user.password)) return res.status(401).json({error: 'Invalid creds'});

        // MOCK JWT for now
        res.json({
            token: 'mock-jwt-token',
            user: {
                id: user.id,
                email: user.email,
                role: user.role,
                phone: user.phone,
                name: user.name,
                profile_image_url: user.profile_image_url
            }
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/auth/google', async (req, res) => {
    const { idToken, name, email, photoUrl, force_create } = req.body;

    try {
        // Check if user exists by email
        const check = await db.query('SELECT * FROM users WHERE email = $1', [email]);

        let user;
        if (check.rows.length > 0) {
            user = check.rows[0];
            // Optional: Update profile info if needed
        } else {
            // Create new user
            const randomPwd = Math.random().toString(36).slice(-8);
            // Note: Phone is empty for google signups initially, might need validation adjustment in DB
            const result = await db.query(
                "INSERT INTO users (email, name, profile_image_url, role, password, phone) VALUES ($1, $2, $3, 'user', $4, $5) RETURNING *",
                [email, name, photoUrl, randomPwd, '']
            );
            user = result.rows[0];
        }

        res.json({
            token: 'mock-jwt-token-google',
            user: {
                id: user.id,
                email: user.email,
                role: user.role,
                phone: user.phone,
                name: user.name,
                profile_image_url: user.profile_image_url
            }
        });

    } catch (err) {
        console.error('Google Auth Error:', err);
        // Fallback for dev environment without DB
        if (err.code === 'ECONNREFUSED') {
            console.warn('⚠️ Database unreachable. Falling back to MOCK login.');
            res.json({
                token: 'mock-jwt-token-google-fallback',
                user: {
                    id: 'mock-id-' + Date.now(),
                    email: email,
                    role: 'user',
                    phone: '',
                    name: name,
                    profile_image_url: photoUrl
                }
            });
            return;
        }

        console.error('SQL Error Detail:', err.detail);
        res.status(500).json({ error: err.message, detail: err.detail });
    }
});

// --- USER ROUTES ---
app.put('/api/users/:id', async (req, res) => {
    const { id } = req.params;
    const { name, profile_image_url, phone, email } = req.body;
    try {
        const result = await db.query(
            'UPDATE users SET name = COALESCE($1, name), profile_image_url = COALESCE($2, profile_image_url), phone = COALESCE($3, phone), email = COALESCE($4, email) WHERE id = $5 RETURNING *',
            [name, profile_image_url, phone, email, id]
        );
        if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });

        const user = result.rows[0];
        res.json({
            id: user.id, email: user.email, role: user.role, phone: user.phone,
            name: user.name, profile_image_url: user.profile_image_url
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Admin Promotion (Debug only - normally requires auth)

// --- ORDER ROUTES (Placeholder) ---
app.get('/api/orders/:userId', async (req, res) => {
    // TODO: Implement GET orders
    res.json([]);
});

app.post('/api/orders', async (req, res) => {
    // TODO: Implement POST order
    const { userId, totalAmount, items } = req.body;
    // Mock success
    res.status(201).json({ id: 'order-' + Date.now(), status: 'pending' });
});

// --- WISHLIST ROUTES ---
app.get('/api/wishlist/:userId', async (req, res) => {
    const { userId } = req.params;
    try {
        const result = await db.query(
            `SELECT p.* FROM products p 
             JOIN wishlist w ON p.id = w.product_id 
             WHERE w.user_id = $1 
             ORDER BY w.created_at DESC`,
            [userId]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/wishlist', async (req, res) => {
    const { userId, productId } = req.body;
    try {
        await db.query(
            'INSERT INTO wishlist (user_id, product_id) VALUES ($1, $2) ON CONFLICT (user_id, product_id) DO NOTHING',
            [userId, productId]
        );
        res.status(201).json({ message: 'Added to wishlist' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.delete('/api/wishlist/:userId/:productId', async (req, res) => {
    const { userId, productId } = req.params;
    try {
        await db.query('DELETE FROM wishlist WHERE user_id = $1 AND product_id = $2', [userId, productId]);
        res.json({ message: 'Removed from wishlist' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- ADDRESS ROUTES ---
app.get('/api/addresses/:userId', async (req, res) => {
    const { userId } = req.params;
    try {
        const result = await db.query('SELECT * FROM addresses WHERE user_id = $1 ORDER BY is_default DESC, created_at DESC', [userId]);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/addresses', async (req, res) => {
    // EXTRACT AND MAP FRONTEND KEYS TO DB COLUMNS
    const { userId, user_id, name, phone, address1, address2, street, city, state, zip, pincode, isDefault, is_default } = req.body;

    // Robust fallback logic
    const finalUserId = userId || user_id;
    const finalStreet = street || (address1 ? `${address1}${address2 ? ', ' + address2 : ''}` : '');
    const finalZip = zip || pincode;
    const finalIsDefault = (isDefault !== undefined) ? isDefault : ((is_default !== undefined) ? is_default : false);

    try {
        if (!finalUserId) throw new Error("User ID is required");

        if (finalIsDefault) {
            await db.query('UPDATE addresses SET is_default = FALSE WHERE user_id = $1', [finalUserId]);
        }
        const result = await db.query(
            'INSERT INTO addresses (user_id, name, phone, street, city, state, zip, is_default) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *',
            [finalUserId, name, phone, finalStreet, city, state, finalZip, finalIsDefault]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error("Address Save Error:", err);
        res.status(500).json({ error: err.message });
    }
});

app.delete('/api/addresses/:userId/:addressId', async (req, res) => {
    const { userId, addressId } = req.params;
    try {
        await db.query('DELETE FROM addresses WHERE id = $1 AND user_id = $2', [addressId, userId]);
        res.json({ message: 'Address deleted' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- PRODUCT ROUTES ---
app.get('/api/products', async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM products ORDER BY created_at DESC');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/products', async (req, res) => {
    // Admin Only TODO: Middleware
    const { name, price, description, sizes, colors, image_urls, is_available } = req.body;
    try {
        const result = await db.query(
            'INSERT INTO products (name, price, description, sizes, colors, image_urls, is_available) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
            [name, price, description, JSON.stringify(sizes), JSON.stringify(colors), JSON.stringify(image_urls), is_available]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.put('/api/products/:id', async (req, res) => {
    const { id } = req.params;
    const { name, price, description, sizes, colors, image_urls, is_available } = req.body;
    try {
        const result = await db.query(
            'UPDATE products SET name = $1, price = $2, description = $3, sizes = $4, colors = $5, image_urls = $6, is_available = $7 WHERE id = $8 RETURNING *',
            [name, price, description, JSON.stringify(sizes), JSON.stringify(colors), JSON.stringify(image_urls), is_available, id]
        );
        if (result.rows.length === 0) return res.status(404).json({ error: 'Product not found' });
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.delete('/api/products/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const result = await db.query('DELETE FROM products WHERE id = $1 RETURNING *', [id]);
        if (result.rows.length === 0) return res.status(404).json({ error: 'Product not found' });
        res.json({ message: 'Product deleted successfully' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- REVIEW ROUTES ---
app.get('/api/reviews/:productId', async (req, res) => {
    const { productId } = req.params;
    try {
        const result = await db.query(
            `SELECT r.*, u.name, u.profile_image_url 
             FROM reviews r 
             JOIN users u ON r.user_id = u.id 
             WHERE r.product_id = $1 
             ORDER BY r.created_at DESC`,
            [productId]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/reviews', async (req, res) => {
    const { userId, productId, rating, reviewText, imageUrls } = req.body;
    try {
        const result = await db.query(
            'INSERT INTO reviews (user_id, product_id, rating, review_text, image_urls) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [userId, productId, rating, reviewText, JSON.stringify(imageUrls || [])]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- NOTIFICATION ROUTES ---
app.get('/api/notifications/:userId', async (req, res) => {
    const { userId } = req.params;
    try {
        const result = await db.query(
            'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC',
            [userId]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.put('/api/notifications/read/:userId', async (req, res) => {
    const { userId } = req.params;
    try {
        await db.query('UPDATE notifications SET is_read = TRUE WHERE user_id = $1', [userId]);
        res.json({ message: 'Notifications marked as read' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/notifications', async (req, res) => {
    // Internal use mainly
    const { userId, title, description, type, metadata } = req.body;
    try {
        const result = await db.query(
            'INSERT INTO notifications (user_id, title, description, type, metadata) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [userId, title, description, type, JSON.stringify(metadata || {})]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, async () => {
    console.log(`Server running on port ${PORT}`);
    await db.initDb();
});
