import sqlite3


class DBManager:
    _instance = None

    def __new__(cls, db_path: str = "wifi.db"):
        if cls._instance is None:
            cls._instance = super(DBManager, cls).__new__(cls)
            cls._instance.db_path = db_path
            cls._instance.connection = sqlite3.connect(db_path)
            cls._instance.cursor = cls._instance.connection.cursor()
            cls._instance.create_table()
        return cls._instance
        