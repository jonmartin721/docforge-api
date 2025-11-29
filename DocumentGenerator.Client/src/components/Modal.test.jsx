import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import Modal from './Modal';

describe('Modal', () => {
    it('does not render when isOpen is false', () => {
        render(
            <Modal isOpen={false} onClose={() => { }} title="Test Modal">
                <div>Modal Content</div>
            </Modal>
        );

        expect(screen.queryByText('Test Modal')).not.toBeInTheDocument();
        expect(screen.queryByText('Modal Content')).not.toBeInTheDocument();
    });

    it('renders correctly when isOpen is true', () => {
        render(
            <Modal isOpen={true} onClose={() => { }} title="Test Modal">
                <div>Modal Content</div>
            </Modal>
        );

        expect(screen.getByText('Test Modal')).toBeInTheDocument();
        expect(screen.getByText('Modal Content')).toBeInTheDocument();
    });

    it('calls onClose when close button is clicked', () => {
        const handleClose = vi.fn();
        render(
            <Modal isOpen={true} onClose={handleClose} title="Test Modal">
                <div>Modal Content</div>
            </Modal>
        );

        const closeButton = screen.getByText('×'); // &times; renders as ×
        fireEvent.click(closeButton);

        expect(handleClose).toHaveBeenCalledTimes(1);
    });

    it('calls onClose when overlay is clicked', () => {
        const handleClose = vi.fn();
        render(
            <Modal isOpen={true} onClose={handleClose} title="Test Modal">
                <div>Modal Content</div>
            </Modal>
        );

        // The overlay is the outer div with class modal-overlay
        // We can find it by looking for the parent of the modal container
        // Or simpler: just click the first div that is the overlay. 
        // However, since we can't easily select by class without setup, let's rely on the structure.
        // The component structure is: <div className="modal-overlay" onClick={onClose}>...</div>

        // Using a test-id or selecting by role would be better, but let's try to click the background.
        // Since the modal container stops propagation, we need to click outside it.
        // Let's assume the overlay covers the screen.

        // A more robust way if we can't modify code:
        // render returns container.
        const { container } = render(
            <Modal isOpen={true} onClose={handleClose} title="Test Modal">
                <div>Modal Content</div>
            </Modal>
        );

        fireEvent.click(container.firstChild); // The overlay is the root element of the component
        expect(handleClose).toHaveBeenCalledTimes(1);
    });

    it('does not call onClose when modal content is clicked', () => {
        const handleClose = vi.fn();
        render(
            <Modal isOpen={true} onClose={handleClose} title="Test Modal">
                <div>Modal Content</div>
            </Modal>
        );

        fireEvent.click(screen.getByText('Test Modal'));
        expect(handleClose).not.toHaveBeenCalled();
    });

    it('calls onClose when Escape key is pressed', () => {
        const handleClose = vi.fn();
        render(
            <Modal isOpen={true} onClose={handleClose} title="Test Modal">
                <div>Modal Content</div>
            </Modal>
        );

        fireEvent.keyDown(document, { key: 'Escape' });
        expect(handleClose).toHaveBeenCalledTimes(1);
    });
});
