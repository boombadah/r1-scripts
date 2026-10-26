"""
Multi-Layer Backup & Permanent Memory Storage Engine
Handles:
1. SQLite FTS5 Full-Text Search & Permanent Memory Journal (Permanent_Memory.sqlite)
2. JSONL Indexed Archives (Permanent_Memory_Vault.jsonl)
3. Obsidian Vault Auto-Sync (D:\\Hearth of noB\\NoB_Vault)
4. Bionic Workspace Auto-Sync
5. Daily Local ZIP Snapshot (c:\\Users\\Boom\\Desktop\\script\\Script\\Backup_Snapshots)
6. GitHub Remote Sync (origin main)
"""

import os
import sys
import time
import json
import sqlite3
import shutil
import zipfile
import subprocess

WORKSPACE_DIR = r"c:\Users\Boom\Desktop\script\Script"
VAULT_STAGE = os.path.join(WORKSPACE_DIR, "Vault_Stage")
BACKUP_DIR = os.path.join(WORKSPACE_DIR, "Backup_Snapshots")
OBSIDIAN_VAULT = r"D:\Hearth of noB\NoB_Vault\03_Active_Projects"
BIONIC_WORKSPACE = r"C:\Users\Boom\.lmstudio\apps\bionic\projects\d49037d8-47f4-5808-9028-c707de117f8f\workspace"
CONV_ID = "69ec2ed6-5685-4a8b-89cf-034a56aa012a"
TRANSCRIPT_PATH = rf"C:\Users\Boom\.gemini\antigravity-ide\brain\{CONV_ID}\.system_generated\logs\transcript.jsonl"

DB_PATH = os.path.join(VAULT_STAGE, "Permanent_Memory.sqlite")
JSONL_PATH = os.path.join(VAULT_STAGE, "Permanent_Memory_Vault.jsonl")

def init_memory_db():
    os.makedirs(VAULT_STAGE, exist_ok=True)
    os.makedirs(BACKUP_DIR, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    # Table for indexed chat turns
    c.execute("""
        CREATE TABLE IF NOT EXISTS chat_turns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            role TEXT,
            content TEXT,
            summary TEXT,
            category TEXT
        )
    """)
    # Full-Text Search virtual table for instant search in < 5ms
    c.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS memory_fts USING fts5(
            content,
            summary,
            category,
            content='chat_turns',
            content_rowid='id'
        )
    """)
    conn.commit()
    conn.close()

def parse_transcript_and_update_memory():
    if not os.path.exists(TRANSCRIPT_PATH):
        print("Transcript not found.")
        return 0

    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    # Get existing turn count
    c.execute("SELECT count(*) FROM chat_turns")
    existing_count = c.fetchone()[0]

    turns = []
    with open(TRANSCRIPT_PATH, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
                stype = obj.get("type")
                content = obj.get("content", "")
                if stype == "USER_INPUT":
                    clean = content.split("<USER_REQUEST>")[-1].split("</USER_REQUEST>")[0].strip()
                    if clean:
                        turns.append(("user", clean, "User Instruction / Query", "user_dialogue"))
                elif stype == "PLANNER_RESPONSE" and content:
                    clean = content.strip()
                    if clean:
                        turns.append(("yachiyo", clean, "Assistant Execution & Response", "assistant_dialogue"))
            except Exception:
                continue

    new_items = turns[existing_count:]
    if new_items:
        ts = time.strftime('%Y-%m-%d %H:%M:%S')
        for role, text, summary, cat in new_items:
            c.execute("""
                INSERT INTO chat_turns (timestamp, role, content, summary, category)
                VALUES (?, ?, ?, ?, ?)
            """, (ts, role, text, summary, cat))
            row_id = c.lastrowid
            c.execute("""
                INSERT INTO memory_fts (rowid, content, summary, category)
                VALUES (?, ?, ?, ?)
            """, (row_id, text, summary, cat))
        conn.commit()
        print(f"Added {len(new_items)} new chat turns to Permanent Memory Database.")

        # Append to JSONL Archive
        with open(JSONL_PATH, 'a', encoding='utf-8') as jf:
            for role, text, summary, cat in new_items:
                record = {
                    "timestamp": ts,
                    "role": role,
                    "content": text,
                    "summary": summary,
                    "category": cat
                }
                jf.write(json.dumps(record, ensure_ascii=False) + "\n")
    else:
        print("Permanent memory database is up to date.")

    conn.close()
    return len(new_items)

def sync_to_obsidian_and_bionic():
    print("Syncing files to Obsidian Vault and Bionic Workspace...")
    files_to_sync = [
        "12Tails_Roblox_Project_Checkpoint.md",
        "Permanent_Memory_Vault.jsonl",
        "Permanent_Memory.sqlite",
        "SHARED_BRAIN_LIVE.md",
        "Tsukimi_Yachiyo_Avatar_Spec.md",
        "Yachiyo_Thai_Voice_Clone_Architecture.md",
        "Kami_no_Manimani_Spec.md"
    ]

    for fname in files_to_sync:
        src = os.path.join(VAULT_STAGE, fname)
        if not os.path.exists(src):
            src = os.path.join(WORKSPACE_DIR, fname)
        if os.path.exists(src):
            # Obsidian
            try:
                os.makedirs(OBSIDIAN_VAULT, exist_ok=True)
                shutil.copy2(src, os.path.join(OBSIDIAN_VAULT, fname))
            except Exception as e:
                print(f"  Obsidian copy error ({fname}):", e)
            # Bionic
            try:
                os.makedirs(BIONIC_WORKSPACE, exist_ok=True)
                shutil.copy2(src, os.path.join(BIONIC_WORKSPACE, fname))
            except Exception as e:
                print(f"  Bionic copy error ({fname}):", e)

    print("  -> Obsidian and Bionic sync complete.")

def create_daily_zip_snapshot():
    date_str = time.strftime('%Y%m%d_%H%M%S')
    zip_name = f"Yachiyo_Memory_Backup_{date_str}.zip"
    zip_path = os.path.join(BACKUP_DIR, zip_name)
    print(f"Creating local ZIP snapshot: {zip_path}...")
    
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        # Add Vault_Stage
        for root, dirs, files in os.walk(VAULT_STAGE):
            for file in files:
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, WORKSPACE_DIR)
                zipf.write(full_path, rel_path)
        # Add scripts
        for script in ["shared_brain_daemon.py", "multi_layer_backup.py"]:
            sp = os.path.join(WORKSPACE_DIR, script)
            if os.path.exists(sp):
                zipf.write(sp, script)
                
    print(f"  -> ZIP Snapshot created successfully ({os.path.getsize(zip_path)} bytes).")

def git_commit_and_push():
    print("Executing Git Commit and Push to origin main...")
    try:
        subprocess.run(["git", "add", "Vault_Stage", "shared_brain_daemon.py", "multi_layer_backup.py"], cwd=WORKSPACE_DIR, check=True)
        commit_msg = f"chore(backup): auto-sync permanent memory & multi-layer vault [{time.strftime('%Y-%m-%d %H:%M:%S')}]"
        # Check if there are changes
        res = subprocess.run(["git", "diff", "--cached", "--quiet"], cwd=WORKSPACE_DIR)
        if res.returncode != 0:
            subprocess.run(["git", "commit", "-m", commit_msg], cwd=WORKSPACE_DIR, check=True)
            subprocess.run(["git", "push", "origin", "main"], cwd=WORKSPACE_DIR, check=True)
            print("  -> Git push completed successfully!")
        else:
            print("  -> Git working tree clean, no changes to commit.")
    except Exception as e:
        print("  Git sync error:", e)

def run_full_backup():
    print("=== STARTING FULL MULTI-LAYER BACKUP & MEMORY SYNC ===")
    init_memory_db()
    parse_transcript_and_update_memory()
    sync_to_obsidian_and_bionic()
    create_daily_zip_snapshot()
    git_commit_and_push()
    print("=== MULTI-LAYER BACKUP COMPLETED 100% ===")

if __name__ == "__main__":
    run_full_backup()
