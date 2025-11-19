import { Link, useNavigate } from 'react-router-dom';
import { authService } from '../services/authService';
import './Navbar.css';

export default function Navbar() {
  const navigate = useNavigate();
  const user = authService.getCurrentUser();

  const handleLogout = () => {
    authService.logout();
    navigate('/login');
  };

  return (
    <nav className="navbar">
      <div className="container">
        <div className="navbar-content">
          <Link to="/" className="navbar-brand">
            <span className="brand-icon">📄</span>
            <span>DocForge</span>
          </Link>

          <div className="navbar-links">
            <Link to="/" className="nav-link">Dashboard</Link>
            <Link to="/templates" className="nav-link">Templates</Link>
            <Link to="/documents" className="nav-link">Documents</Link>
          </div>

          <div className="navbar-user">
            <span className="user-email">{user?.username}</span>
            <button onClick={handleLogout} className="btn btn-sm btn-secondary">
              Logout
            </button>
          </div>
        </div>
      </div>
    </nav>
  );
}
