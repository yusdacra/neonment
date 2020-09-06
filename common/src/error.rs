pub use std::net::AddrParseError;

#[derive(Debug)]
pub enum NetworkError {
    Addr(AddrParseError),
    Parse(bincode::ErrorKind),
    Compression(std::io::Error),
    AlreadyCompressed,
}

impl From<Box<bincode::ErrorKind>> for NetworkError {
    fn from(other: Box<bincode::ErrorKind>) -> Self {
        NetworkError::Parse(*other)
    }
}

impl From<std::io::Error> for NetworkError {
    fn from(other: std::io::Error) -> Self {
        NetworkError::Compression(other)
    }
}

impl From<AddrParseError> for NetworkError {
    fn from(other: AddrParseError) -> Self {
        NetworkError::Addr(other)
    }
}
