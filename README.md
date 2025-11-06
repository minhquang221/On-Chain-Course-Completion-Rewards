# 🎓 On-Chain Course Completion Rewards

A Clarity smart contract that enables students to earn tokens for completing courses and achieving milestones on the Stacks blockchain.

## 📋 Features

- 🏫 **Course Management**: Create and manage educational courses
- 🎯 **Milestone System**: Set up achievement milestones within courses  
- 🎟️ **Student Enrollment**: Students can enroll in available courses
- 🏆 **Token Rewards**: Earn LEARN tokens for completing milestones and courses
- 📊 **Progress Tracking**: Monitor student progress and completion status
- 💰 **Token Transfer**: Transfer earned tokens between accounts

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Deploy the contract using Clarinet

```bash
clarinet deploy
```

## 📖 Usage

### For Contract Owner

#### Create a Course
```clarity
(contract-call? .On-Chain-Course-Completion-Rewards create-course "Blockchain Basics" u1000 u5)
```

#### Add Milestones
```clarity
(contract-call? .On-Chain-Course-Completion-Rewards add-milestone u1 u1 "Complete Module 1" u100)
```

#### Mint Tokens for Rewards
```clarity
(contract-call? .On-Chain-Course-Completion-Rewards mint-tokens-to-contract u10000)
```

### For Students

#### Enroll in a Course
```clarity
(contract-call? .On-Chain-Course-Completion-Rewards enroll-student u1)
```

#### Complete a Milestone
```clarity
(contract-call? .On-Chain-Course-Completion-Rewards complete-milestone u1 u1)
```

#### Complete the Entire Course
```clarity
(contract-call? .On-Chain-Course-Completion-Rewards complete-course u1)
```

#### Transfer Tokens
```clarity
(contract-call? .On-Chain-Course-Completion-Rewards transfer-tokens u500 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## 🔍 Read-Only Functions

- `get-course`: Get course information
- `get-enrollment`: Check student enrollment status
- `get-milestone`: Get milestone details
- `get-token-balance`: Check token balance
- `get-student-progress`: View student's course progress
- `get-total-rewards-distributed`: Total tokens distributed as rewards

## 🎯 Contract Structure

### Data Maps
- **courses**: Store course information and metadata
- **enrollments**: Track student enrollments and progress
- **milestones**: Define course milestones and rewards
- **student-milestones**: Record milestone completions

### Token System
- **learn-token**: Fungible token rewarded for achievements
- Automatic minting upon milestone/course completion
- Transferable between accounts

## 🛡️ Security Features

- Owner-only functions for course management
- Enrollment verification for milestone completion
- Prevention of duplicate completions
- Active status checks for courses and milestones

## 📊 Example Workflow

1. 👨‍🏫 **Instructor** creates a course with 3 milestones
2. 📚 **Student** enrolls in the course
3. 🎯 **Student** completes milestone 1 → receives 100 LEARN tokens
4. 🎯 **Student** completes milestone 2 → receives 150 LEARN tokens  
5. 🎯 **Student** completes milestone 3 → receives 200 LEARN tokens
6. 🏆 **Student** completes the course → receives 1000 LEARN tokens bonus
7. 💸 **Student** can transfer tokens or use them in other applications

## 🔧 Error Codes

- `u100`: Owner only operation
- `u101`: Resource not found
- `u102`: Resource already exists
- `u103`: Student not enrolled
- `u104`: Already completed
- `u105`: Insufficient balance
- `u106`: Invalid milestone
- `u107`: Course not active

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is open source and available under the MIT License.
```

**Git Commit Message:**
```
feat: implement on-chain course completion rewards system with milestone tracking
```

**GitHub Pull Request Title:**
```
🎓 Add On-Chain Course Completion Rewards Smart Contract
```

**GitHub Pull Request Description:**
```
## Summary
This PR introduces a comprehensive smart contract system for rewarding students with tokens upon completing educational courses and milestones.

## What's Added
- ✅ Complete Clarity smart contract for course management
- ✅ Fungible token (LEARN) reward system  
- ✅ Student enrollment and progress tracking
- ✅ Milestone-based achievement system
- ✅ Course completion rewards
- ✅ Token transfer functionality
- ✅ Comprehensive README with usage examples

## Key Features
- Course creation and management by contract owner
- Student self-enrollment system
- Automatic token minting for milestone/course completion
- Progress tracking and completion verification
- Security measures preventing duplicate rewards

## Testing
- All core functions implemented and ready for testing
- Error handling for edge cases included
- Owner-only restrictions properly enforced

Ready for deployment and testing on Stacks testnet.
