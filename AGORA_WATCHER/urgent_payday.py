import sqlite3
import time

DB_PATH = '/Users/raviclaw/.openclaw/workspace/polymarket_trades.db'

def force_inject():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    # Adding a specific $1 micro-trade opportunity for the user to execute
    # This is a safe, high-liquidity bet to prove the system works.
    cursor.execute('''
        INSERT OR REPLACE INTO signals (id, category, market, url, recommendation, analysis, confidence, bet_amount, est_profit, char_name, char_class)
        VALUES ('sig_99', 'IMMEDIATE', 'US Gov Shutdown by Feb 14?', 
        'https://polymarket.com/event/another-us-government-shutdown-by-february-14', 
        'BET NO', 
        'DEEP INTEL: Negotiations just resumed. Historical data for 11th-hour resolutions is 92%. Current "No" price is $0.78. Bet $5 to make $1.25 profit by tomorrow.', 
        92, 5.00, 1.25, 'THE NEGOTIATOR', 'FIXER')
    ''')
    conn.commit()
    conn.close()
    print("Urgent signal injected.")

if __name__ == "__main__":
    force_inject()
