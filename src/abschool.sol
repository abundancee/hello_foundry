//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

//to interact with the ERC20 token contract for payment of staff, check their balance and when students pays fees
interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

//declared my contract
contract abschool {
    
    //i created two structs to hold the details of students and staff members
    struct Student {
        uint8 id;
        string name;
        uint8 level;
        address studentAccount;
        bool paymentStatus;
        uint256 paymentTimestamp;
    }

    struct Staff {
        uint8 id;
        string name;
        address acct;
        uint256 salaryAccumulated;
        uint256 lastPaymentDate;
    }

   //i created two arrays to hold the details of students and staff members
    Student[] public students;
    Staff[] public staff;

   //i created mappings to easily access the details of students and staff members by their ID, and to keep track of the levels and their corresponding fees, and to keep track of the balances of staff members
    mapping(uint256 => uint256) public Levels;
    mapping(address => uint256) public staffBalances;
    mapping(uint8 => Student) public studentsByID;
    mapping(uint8 => Staff) public staffByID;

    //set state variables to keep track of the salary for staff members, the number of staff and students, the owner of the contract, and the address of the ERC20 token used for payments
    uint256 private salary = 5 * (10 ** 18); // Default salary set to 5 tokens 
    uint8 staff_id; 
    uint8 student_id;
    address owner;
    IERC20 public tokenAddress;

    //i created events to emit when a student is registered, when a staff member is registered, when a student pays their fees, and when a staff member is paid
    event StudentRegistered(uint8 indexed studentId, string name, uint8 level, address indexed account);
    event StaffRegistered(uint8 indexed staffId, string name, address indexed account);
    event StudentFeePaid(uint8 indexed studentId, uint256 amount, uint256 timestamp);
    event StaffPaid(uint8 indexed staffId, uint256 amount, uint256 timestamp);

    //i created a constructor
    constructor(address _tokenAddress) {
        Levels[100] = 1 ;
        Levels[200] = 2 ;
        Levels[300] = 3 ;
        Levels[400] = 4 ;
        tokenAddress = IERC20(_tokenAddress);
        owner = msg.sender;
    }

    //i created a modifier to restrict access to certain functions to only the owner of the contract
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can call this function");
        _;
    }

    function registerStudent(string memory _name, uint8 _level, address _studentAccount) external onlyOwner {
        require(_studentAccount != address(0), "Invalid student address");
        require(_level >= 100 && _level <= 400, "Invalid level. Must be 100-400");
        require(Levels[_level] > 0, "Level does not exist");
        
        student_id = student_id + 1;
        
        Student memory newStudent = Student(
            student_id,
            _name,
            _level,
            _studentAccount,
            false,
            0
        );
        
        students.push(newStudent);
        studentsByID[student_id] = newStudent;
        
        emit StudentRegistered(student_id, _name, _level, _studentAccount);
    }

    function payStudentFee(uint8 _studentId) external {
        require(_studentId > 0 && _studentId <= student_id, "Invalid student ID");
        
        Student storage student = studentsByID[_studentId];
        require(student.studentAccount != address(0), "Student does not exist");
        require(!student.paymentStatus, "Student fees already paid");
        
        uint256 feeAmount = Levels[student.level];
        require(feeAmount > 0, "Invalid fee amount");
        
        require(
            tokenAddress.transferFrom(msg.sender, address(this), feeAmount),
            "Payment failed"
        );
        
        student.paymentStatus = true;
        student.paymentTimestamp = block.timestamp;
        
        // Update student in students array
        for (uint256 i = 0; i < students.length; i++) {
            if (students[i].id == _studentId) {
                students[i] = student;
                break;
            }
        }
        
        emit StudentFeePaid(_studentId, feeAmount, block.timestamp);
    }

    function createStaff(string memory _name, address _acct) external onlyOwner {
        require(_acct != address(0), "Invalid address");
        
        staff_id = staff_id + 1;
        
        Staff memory newStaff = Staff(
            staff_id,
            _name,
            _acct,
            0,
            0
        );
        
        staff.push(newStaff);
        staffByID[staff_id] = newStaff;
        
        emit StaffRegistered(staff_id, _name, _acct);
    }

    function payStaff(uint8 _id) external onlyOwner {
        require(_id > 0 && _id <= staff_id, "Invalid staff ID");
        
        Staff storage staffMember = staffByID[_id];
        require(staffMember.acct != address(0), "Staff does not exist");
        
        uint256 paymentAmount = salary;
        require(
            tokenAddress.transfer(staffMember.acct, paymentAmount),
            "Staff payment failed"
        );
        
        staffMember.salaryAccumulated += paymentAmount;
        staffMember.lastPaymentDate = block.timestamp;
        
        // Update staff in staff array
        for (uint256 i = 0; i < staff.length; i++) {
            if (staff[i].id == _id) {
                staff[i] = staffMember;
                break;
            }
        }
        
        emit StaffPaid(_id, paymentAmount, block.timestamp);
    }

    function getAllStudents() external view returns (Student[] memory) {
        return students;
    }

    function getStudentDetails(uint8 _studentId) external view returns (Student memory) {
        require(_studentId > 0 && _studentId <= student_id, "Invalid student ID");
        return studentsByID[_studentId];
    }

    function getAllStaff() external view returns (Staff[] memory) {
        return staff;
    }

    function getStaffDetails(uint8 _staffId) external view returns (Staff memory) {
        require(_staffId > 0 && _staffId <= staff_id, "Invalid staff ID");
        return staffByID[_staffId];
    }

    function updatePaymentStatus(uint8 _studentId) external onlyOwner {
        require(_studentId > 0 && _studentId <= student_id, "Invalid student ID");
        
        Student storage student = studentsByID[_studentId];
        require(student.studentAccount != address(0), "Student does not exist");
        
        student.paymentStatus = true;
        student.paymentTimestamp = block.timestamp;
        
        // Update student in students array
        for (uint256 i = 0; i < students.length; i++) {
            if (students[i].id == _studentId) {
                students[i] = student;
                break;
            }
        }
    }

    function getStudentCount() external view returns (uint256) {
        return students.length;
    }

    function getStaffCount() external view returns (uint256) {
        return staff.length;
    }

    function setSalary(uint256 _newSalary) external onlyOwner {
        salary = _newSalary;
    }

    function setLevelFee(uint256 _level, uint256 _fee) external onlyOwner {
        require(_level >= 100 && _level <= 400, "Invalid level");
        Levels[_level] = _fee;
    }

}
