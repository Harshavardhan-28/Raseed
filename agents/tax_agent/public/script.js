document.addEventListener('DOMContentLoaded', () => {
    const runButton = document.getElementById('run-agent-btn');
    const responseContainer = document.getElementById('response-container');
    const userIdInput = document.getElementById('userId');
    const taskSelect = document.getElementById('task');
    const timeframeSelect = document.getElementById('timeframe');

    runButton.addEventListener('click', async () => {
        const userId = userIdInput.value;
        const task = taskSelect.value;
        const timeframe = timeframeSelect.value;

        if (!userId) {
            responseContainer.textContent = 'Error: Please enter a User ID.';
            return;
        }

        responseContainer.textContent = 'Agent is thinking...';
        
        try {
            const response = await fetch('http://localhost:8000/analyze', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ userId, task, timeframe }),
            });

            const result = await response.json();

            if (!response.ok) {
                throw new Error(result.error || 'An unknown error occurred.');
            }

            // Pretty-print the JSON response
            responseContainer.textContent = JSON.stringify(result, null, 2);

        } catch (error) {
            responseContainer.textContent = `Error: ${error.message}`;
        }
    });
});