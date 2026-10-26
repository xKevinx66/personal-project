/* Author: xKevinx66 */
/* VehicleSystem  */
/*    2025/7/6    */
#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <algorithm>
#include <map>
#include <iomanip>
#include <sstream>
using namespace std;

// ===================== 车辆基类 =====================
class Vehicle {
protected:
    string licensePlate;
    string brand;
    string model;
    int year;
    double dailyRate;
    bool isRented;
    string renterName;
public:
    Vehicle() : licensePlate(""), brand(""), model(""), year(0), dailyRate(0.0), isRented(false), renterName("") {}
    Vehicle(string plate, string b, string m, int y, double rate)
        : licensePlate(plate), brand(b), model(m), year(y), dailyRate(rate), isRented(false), renterName("") {}
    virtual ~Vehicle() {}
    virtual void displayInfo() const = 0; // 显示车辆信息
    virtual string getVehicleType() const = 0; // 获取车辆类型
    virtual double calculateRentalCost(int days) const = 0; // 计算租金
    bool rentVehicle(const string& renter) {
        if (isRented) return false;
        isRented = true;
        renterName = renter;
        return true;
    }
    bool returnVehicle() {
        if (!isRented) return false;
        isRented = false;
        renterName = "";
        return true;
    }
    // Getter/Setter
    string getLicensePlate() const { return licensePlate; }
    string getBrand() const { return brand; }
    string getModel() const { return model; }
    int getYear() const { return year; }
    double getDailyRate() const { return dailyRate; }
    bool getIsRented() const { return isRented; }
    string getRenterName() const { return renterName; }
    void setDailyRate(double rate) { dailyRate = rate; }
    void setBrand(const string& b) { brand = b; }
    void setModel(const string& m) { model = m; }
};

// ===================== 小汽车类 =====================
class Car : public Vehicle {
private:
    int numDoors;
    string fuelType;
    bool hasAirConditioning;
public:
    Car() : Vehicle(), numDoors(4), fuelType("Gasoline"), hasAirConditioning(false) {}
    Car(string plate, string b, string m, int y, double rate, int doors, string fuel, bool ac)
        : Vehicle(plate, b, m, y, rate), numDoors(doors), fuelType(fuel), hasAirConditioning(ac) {}
    void displayInfo() const override {
        cout << "--- 小汽车信息 ---" << endl;
        cout << "车牌: " << licensePlate << endl;
        cout << "品牌: " << brand << endl;
        cout << "型号: " << model << endl;
        cout << "年份: " << year << endl;
        cout << fixed << setprecision(2);
        cout << "日租金: ￥" << dailyRate << endl;
        cout << "状态: " << (isRented ? ("已租给 " + renterName) : "可租") << endl;
        cout << "车门数: " << numDoors << endl;
        cout << "燃油类型: " << fuelType << endl;
        cout << "空调: " << (hasAirConditioning ? "有" : "无") << endl;
    }
    string getVehicleType() const override { return "Car"; }
    double calculateRentalCost(int days) const override {
        return days * dailyRate + 10.0; // 小汽车有10元附加
    }
    int getNumDoors() const { return numDoors; }
    string getFuelType() const { return fuelType; }
    bool getHasAirConditioning() const { return hasAirConditioning; }
    void setNumDoors(int doors) { numDoors = doors; }
    void setFuelType(const string& fuel) { fuelType = fuel; }
    void setHasAirConditioning(bool ac) { hasAirConditioning = ac; }
};

// ===================== 摩托车类 =====================
class Motorcycle : public Vehicle {
private:
    int engineSize;
    string bikeType;
    bool hasSidecar;
public:
    Motorcycle() : Vehicle(), engineSize(0), bikeType("Sport"), hasSidecar(false) {}
    Motorcycle(string plate, string b, string m, int y, double rate, int engine, string type, bool sidecar)
        : Vehicle(plate, b, m, y, rate), engineSize(engine), bikeType(type), hasSidecar(sidecar) {}
    void displayInfo() const override {
        cout << "--- 摩托车信息 ---" << endl;
        cout << "车牌: " << licensePlate << endl;
        cout << "品牌: " << brand << endl;
        cout << "型号: " << model << endl;
        cout << "年份: " << year << endl;
        cout << fixed << setprecision(2);
        cout << "日租金: ￥" << dailyRate << endl;
        cout << "状态: " << (isRented ? ("已租给 " + renterName) : "可租") << endl;
        cout << "排量: " << engineSize << " CC" << endl;
        cout << "类型: " << bikeType << endl;
        cout << "有无边车: " << (hasSidecar ? "有" : "无") << endl;
    }
    string getVehicleType() const override { return "Motorcycle"; }
    double calculateRentalCost(int days) const override {
        return days * dailyRate;
    }
    int getEngineSize() const { return engineSize; }
    string getBikeType() const { return bikeType; }
    bool getHasSidecar() const { return hasSidecar; }
    void setEngineSize(int engine) { engineSize = engine; }
    void setBikeType(const string& type) { bikeType = type; }
    void setHasSidecar(bool sidecar) { hasSidecar = sidecar; }
};

// ===================== 车辆管理模板类 =====================
template<typename T>
class VehicleManager {
private:
    vector<T*> vehicles;
    map<string, T*> plateIndex;
public:
    VehicleManager() {}
    ~VehicleManager() { clearAll(); }
    // 添加车辆
    bool addVehicle(T* vehicle) {
        string plate = vehicle->getLicensePlate();
        if (plateIndex.count(plate)) return false;
        vehicles.push_back(vehicle);
        plateIndex[plate] = vehicle;
        return true;
    }
    // 删除车辆
    bool removeVehicle(const string& licensePlate) {
        auto it = plateIndex.find(licensePlate);
        if (it == plateIndex.end()) return false;
        T* v = it->second;
        vehicles.erase(remove(vehicles.begin(), vehicles.end(), v), vehicles.end());
        plateIndex.erase(it);
        delete v;
        return true;
    }
    // 查找车辆
    T* findVehicle(const string& licensePlate) {
        auto it = plateIndex.find(licensePlate);
        if (it == plateIndex.end()) return nullptr;
        return it->second;
    }
    // 显示所有车辆
    void displayAllVehicles() const {
        if (vehicles.empty()) {
            cout << "系统中暂无车辆。" << endl;
            return;
        }
        for (const auto& v : vehicles) v->displayInfo();
        cout << "车辆总数: " << vehicles.size() << endl;
        cout << "可租: " << getAvailableCount() << ", 已租: " << getRentedCount() << endl;
    }
    // 显示可租车辆
    void displayAvailableVehicles() const {
        int count = 0;
        for (const auto& v : vehicles)
            if (!v->getIsRented()) { v->displayInfo(); ++count; }
        cout << "可租车辆数: " << count << endl;
    }
    // 显示已租车辆
    void displayRentedVehicles() const {
        int count = 0;
        for (const auto& v : vehicles)
            if (v->getIsRented()) { v->displayInfo(); ++count; }
        cout << "已租车辆数: " << count << endl;
    }
    // 租车
    bool rentVehicle(const string& licensePlate, const string& renterName) {
        T* v = findVehicle(licensePlate);
        if (!v) return false;
        return v->rentVehicle(renterName);
    }
    // 还车
    bool returnVehicle(const string& licensePlate) {
        T* v = findVehicle(licensePlate);
        if (!v) return false;
        return v->returnVehicle();
    }
    // 统计
    double calculateTotalValue() const {
        double sum = 0;
        for (const auto& v : vehicles) sum += v->getDailyRate();
        return sum;
    }
    T* findMostExpensive() const {
        if (vehicles.empty()) return nullptr;
        return *max_element(vehicles.begin(), vehicles.end(),
            [](T* a, T* b) { return a->getDailyRate() < b->getDailyRate(); });
    }
    T* findLeastExpensive() const {
        if (vehicles.empty()) return nullptr;
        return *min_element(vehicles.begin(), vehicles.end(),
            [](T* a, T* b) { return a->getDailyRate() < b->getDailyRate(); });
    }
    int getAvailableCount() const {
        return count_if(vehicles.begin(), vehicles.end(), [](T* v) { return !v->getIsRented(); });
    }
    int getRentedCount() const {
        return count_if(vehicles.begin(), vehicles.end(), [](T* v) { return v->getIsRented(); });
    }
    // 文件保存
    void saveToFile(const string& filename) const {
        ofstream ofs(filename);
        if (!ofs) {
            cout << "文件 " << filename << " 打开失败！" << endl;
            return;
        }
        for (const auto& v : vehicles) {
            if (v->getVehicleType() == "Car") {
                Car* c = dynamic_cast<Car*>(v);
                ofs << "Car," << c->getLicensePlate() << "," << c->getBrand() << "," << c->getModel() << ","
                    << c->getYear() << "," << fixed << setprecision(2) << c->getDailyRate() << ","
                    << (c->getIsRented() ? "1" : "0") << "," << c->getRenterName() << ","
                    << c->getNumDoors() << "," << c->getFuelType() << "," << (c->getHasAirConditioning() ? "1" : "0") << endl;
            } else if (v->getVehicleType() == "Motorcycle") {
                Motorcycle* m = dynamic_cast<Motorcycle*>(v);
                ofs << "Motorcycle," << m->getLicensePlate() << "," << m->getBrand() << "," << m->getModel() << ","
                    << m->getYear() << "," << fixed << setprecision(2) << m->getDailyRate() << ","
                    << (m->getIsRented() ? "1" : "0") << "," << m->getRenterName() << ","
                    << m->getEngineSize() << "," << m->getBikeType() << "," << (m->getHasSidecar() ? "1" : "0") << endl;
            }
        }
        ofs.close();
        cout << "数据已保存到 " << filename << "！" << endl;
    }
    // 文件读取
    void loadFromFile(const string& filename) {
        ifstream ifs(filename);
        if (!ifs) {
            cout << "文件 " << filename << " 打开失败！" << endl;
            return;
        }
        clearAll();
        string line;
        int count = 0;
        while (getline(ifs, line)) {
            stringstream ss(line);
            string type, plate, brand, model, yearStr, rateStr, isRentedStr, renter, doorsOrEngine, fuelOrType, acOrSidecar;
            getline(ss, type, ',');
            getline(ss, plate, ',');
            getline(ss, brand, ',');
            getline(ss, model, ',');
            getline(ss, yearStr, ',');
            getline(ss, rateStr, ',');
            getline(ss, isRentedStr, ',');
            getline(ss, renter, ',');
            getline(ss, doorsOrEngine, ',');
            getline(ss, fuelOrType, ',');
            getline(ss, acOrSidecar, ',');
            int year = stoi(yearStr);
            double rate = stod(rateStr);
            bool isRented = (isRentedStr == "1");
            if (type == "Car") {
                int doors = stoi(doorsOrEngine);
                bool ac = (acOrSidecar == "1");
                Car* c = new Car(plate, brand, model, year, rate, doors, fuelOrType, ac);
                if (isRented) c->rentVehicle(renter);
                addVehicle(c);
                ++count;
            } else if (type == "Motorcycle") {
                int engine = stoi(doorsOrEngine);
                bool sidecar = (acOrSidecar == "1");
                Motorcycle* m = new Motorcycle(plate, brand, model, year, rate, engine, fuelOrType, sidecar);
                if (isRented) m->rentVehicle(renter);
                addVehicle(m);
                ++count;
            }
        }
        ifs.close();
        cout << "已从 " << filename << " 读取 " << count << " 条车辆数据。" << endl;
    }
    int getTotalCount() const { return vehicles.size(); }
    bool isEmpty() const { return vehicles.empty(); }
    void clearAll() {
        for (auto v : vehicles) delete v;
        vehicles.clear();
        plateIndex.clear();
    }
    // 其他功能略
    vector<T*> getAllVehicles() const { return vehicles; }
};

// ===================== 车辆租赁系统主类 =====================
class VehicleRentalSystem {
private:
    VehicleManager<Vehicle> manager;
public:
    void run();
    void displayMainMenu();
    void handleAddVehicle();
    void handleDisplayVehicles();
    void handleSearchVehicle();
    void handleRentVehicle();
    void handleReturnVehicle();
    void handleStatistics();
    void handleFileOperations();
    void handleUpdateVehicle();
private:
    void displayFileMenu();
    void clearScreen();
    void pauseScreen();
};

void VehicleRentalSystem::run() {
    int choice;
    do {
        displayMainMenu();
        cout << "请输入功能编号 (1-11): ";
        cin >> choice;
        cin.ignore();
        switch (choice) {
        case 1: handleAddVehicle(); break;
        case 2: handleDisplayVehicles(); break;
        case 3: manager.displayAvailableVehicles(); pauseScreen(); break;
        case 4: manager.displayRentedVehicles(); pauseScreen(); break;
        case 5: handleSearchVehicle(); break;
        case 6: handleRentVehicle(); break;
        case 7: handleReturnVehicle(); break;
        case 8: handleUpdateVehicle(); break;
        case 9: handleStatistics(); break;
        case 10: handleFileOperations(); break;
        case 11: cout << "系统已退出。" << endl; break;
        default: cout << "无效选择，请输入1-11之间的数字。" << endl; pauseScreen();
        }
    } while (choice != 11);
}

void VehicleRentalSystem::displayMainMenu() {
    clearScreen();
    cout << "===============================================" << endl;
    cout << "         车辆租赁管理系统                      " << endl;
    cout << "===============================================" << endl;
    cout << "1. 添加车辆" << endl;
    cout << "2. 显示所有车辆" << endl;
    cout << "3. 显示可租车辆" << endl;
    cout << "4. 显示已租车辆" << endl;
    cout << "5. 查询车辆" << endl;
    cout << "6. 租赁车辆" << endl;
    cout << "7. 归还车辆" << endl;
    cout << "8. 更新车辆信息" << endl;
    cout << "9. 统计信息" << endl;
    cout << "10. 文件操作" << endl;
    cout << "11. 退出" << endl;
    cout << "===============================================" << endl;
}

void VehicleRentalSystem::handleAddVehicle() {
    cout << "=== 添加车辆 ===" << endl;
    cout << "请选择车辆类型: 1. 小汽车 2. 摩托车" << endl;
    int type;
    cin >> type;
    cin.ignore();
    string plate, brand, model;
    int year;
    double rate;
    cout << "请输入车牌: ";
    getline(cin, plate);
    if (manager.findVehicle(plate)) {
        cout << "错误: 该车牌已存在！" << endl;
        pauseScreen();
        return;
    }
    cout << "请输入品牌: ";
    getline(cin, brand);
    cout << "请输入型号: ";
    getline(cin, model);
    cout << "请输入年份: ";
    cin >> year;
    cout << "请输入日租金: ";
    cin >> rate;
    cin.ignore();
    if (type == 1) {
        int doors;
        string fuel;
        char ac;
        cout << "请输入车门数: ";
        cin >> doors;
        cin.ignore();
        cout << "请输入燃油类型: ";
        getline(cin, fuel);
        cout << "有空调？(y/n): ";
        cin >> ac;
        bool hasAC = (ac == 'y' || ac == 'Y');
        Car* c = new Car(plate, brand, model, year, rate, doors, fuel, hasAC);
        if (manager.addVehicle(c))
            cout << "小汽车添加成功！" << endl;
    } else if (type == 2) {
        int engine;
        string bikeType;
        char sidecar;
        cout << "请输入排量(CC): ";
        cin >> engine;
        cin.ignore();
        cout << "请输入类型: ";
        getline(cin, bikeType);
        cout << "有边车？(y/n): ";
        cin >> sidecar;
        bool hasSide = (sidecar == 'y' || sidecar == 'Y');
        Motorcycle* m = new Motorcycle(plate, brand, model, year, rate, engine, bikeType, hasSide);
        if (manager.addVehicle(m))
            cout << "摩托车添加成功！" << endl;
    } else {
        cout << "车辆类型选择错误！" << endl;
    }
    pauseScreen();
}

void VehicleRentalSystem::handleDisplayVehicles() {
    cout << "=== 所有车辆 ===" << endl;
    manager.displayAllVehicles();
    pauseScreen();
}

void VehicleRentalSystem::handleSearchVehicle() {
    cout << "=== 查询车辆 ===" << endl;
    cout << "请输入车牌: ";
    string plate;
    getline(cin, plate);
    Vehicle* v = manager.findVehicle(plate);
    if (!v) {
        cout << "未找到该车牌车辆！" << endl;
    } else {
        v->displayInfo();
    }
    pauseScreen();
}

void VehicleRentalSystem::handleRentVehicle() {
    cout << "=== 租赁车辆 ===" << endl;
    cout << "请输入车牌: ";
    string plate;
    getline(cin, plate);
    Vehicle* v = manager.findVehicle(plate);
    if (!v) {
        cout << "未找到该车牌车辆！" << endl;
        pauseScreen();
        return;
    }
    if (v->getIsRented()) {
        cout << "该车辆已被租赁！" << endl;
        pauseScreen();
        return;
    }
    cout << "请输入租赁人姓名: ";
    string renter;
    getline(cin, renter);
    cout << "请输入租赁天数: ";
    int days;
    cin >> days;
    cin.ignore();
    double total = v->calculateRentalCost(days);
    cout << "租金总计: ￥" << fixed << setprecision(2) << total << endl;
    if (v->rentVehicle(renter)) {
        cout << "租赁成功！" << endl;
    }
    pauseScreen();
}

void VehicleRentalSystem::handleReturnVehicle() {
    cout << "=== 归还车辆 ===" << endl;
    cout << "请输入车牌: ";
    string plate;
    getline(cin, plate);
    Vehicle* v = manager.findVehicle(plate);
    if (!v) {
        cout << "未找到该车牌车辆！" << endl;
        pauseScreen();
        return;
    }
    if (!v->getIsRented()) {
        cout << "该车辆当前未被租赁！" << endl;
        pauseScreen();
        return;
    }
    if (v->returnVehicle()) {
        cout << "归还成功！" << endl;
    }
    pauseScreen();
}

void VehicleRentalSystem::handleUpdateVehicle() {
    cout << "=== 更新车辆信息 ===" << endl;
    cout << "请输入车牌: ";
    string plate;
    getline(cin, plate);
    Vehicle* v = manager.findVehicle(plate);
    if (!v) {
        cout << "未找到该车牌车辆！" << endl;
        pauseScreen();
        return;
    }
    cout << "当前信息:" << endl;
    v->displayInfo();
    cout << "新品牌(回车跳过): ";
    string brand;
    getline(cin, brand);
    if (!brand.empty()) v->setBrand(brand);
    cout << "新型号(回车跳过): ";
    string model;
    getline(cin, model);
    if (!model.empty()) v->setModel(model);
    cout << "新日租金(0跳过): ";
    double rate;
    cin >> rate;
    cin.ignore();
    if (rate > 0) v->setDailyRate(rate);
    if (v->getVehicleType() == "Car") {
        Car* c = dynamic_cast<Car*>(v);
        cout << "新车门数(0跳过): ";
        int doors;
        cin >> doors;
        cin.ignore();
        if (doors > 0) c->setNumDoors(doors);
        cout << "新燃油类型(回车跳过): ";
        string fuel;
        getline(cin, fuel);
        if (!fuel.empty()) c->setFuelType(fuel);
        cout << "有空调？(y/n, 回车跳过): ";
        string ac;
        getline(cin, ac);
        if (!ac.empty()) c->setHasAirConditioning(ac[0] == 'y' || ac[0] == 'Y');
    } else if (v->getVehicleType() == "Motorcycle") {
        Motorcycle* m = dynamic_cast<Motorcycle*>(v);
        cout << "新排量(0跳过): ";
        int engine;
        cin >> engine;
        cin.ignore();
        if (engine > 0) m->setEngineSize(engine);
        cout << "新类型(回车跳过): ";
        string type;
        getline(cin, type);
        if (!type.empty()) m->setBikeType(type);
        cout << "有边车？(y/n, 回车跳过): ";
        string sidecar;
        getline(cin, sidecar);
        if (!sidecar.empty()) m->setHasSidecar(sidecar[0] == 'y' || sidecar[0] == 'Y');
    }
    cout << "车辆信息已更新！" << endl;
    pauseScreen();
}

void VehicleRentalSystem::handleStatistics() {
    cout << "=== 统计信息 ===" << endl;
    int total = manager.getTotalCount();
    int available = manager.getAvailableCount();
    int rented = manager.getRentedCount();
    cout << "车辆总数: " << total << endl;
    cout << "可租车辆: " << available << endl;
    cout << "已租车辆: " << rented << endl;
    int cars = 0, motos = 0;
    for (auto v : manager.getAllVehicles()) {
        if (v->getVehicleType() == "Car") ++cars;
        else if (v->getVehicleType() == "Motorcycle") ++motos;
    }
    cout << "小汽车: " << cars << " 辆, 摩托车: " << motos << " 辆" << endl;
    double totalValue = manager.calculateTotalValue();
    double rentedValue = 0, availableValue = 0;
    for (auto v : manager.getAllVehicles()) {
        if (v->getIsRented()) rentedValue += v->getDailyRate();
        else availableValue += v->getDailyRate();
    }
    cout << "总日租金: ￥" << totalValue << endl;
    cout << "当前租出日租金: ￥" << rentedValue << endl;
    cout << "可租车辆日租金: ￥" << availableValue << endl;
    Vehicle* most = manager.findMostExpensive();
    Vehicle* least = manager.findLeastExpensive();
    if (most)
        cout << "最贵车辆: " << most->getBrand() << " " << most->getModel()
        << " (" << most->getLicensePlate() << ") - ￥" << most->getDailyRate() << endl;
    if (least)
        cout << "最便宜车辆: " << least->getBrand() << " " << least->getModel()
        << " (" << least->getLicensePlate() << ") - ￥" << least->getDailyRate() << endl;
    if (total > 0) {
        auto all = manager.getAllVehicles();
        auto newest = *max_element(all.begin(), all.end(), [](Vehicle* a, Vehicle* b) { return a->getYear() < b->getYear(); });
        auto oldest = *min_element(all.begin(), all.end(), [](Vehicle* a, Vehicle* b) { return a->getYear() < b->getYear(); });
        double avgYear = 0;
        for (auto v : all) avgYear += v->getYear();
        avgYear /= total;
        cout << "最新车辆: " << newest->getYear() << " " << newest->getBrand() << " " << newest->getModel() << endl;
        cout << "最老车辆: " << oldest->getYear() << " " << oldest->getBrand() << " " << oldest->getModel() << endl;
        cout << "平均年份: " << fixed << setprecision(1) << avgYear << endl;
    }
    pauseScreen();
}

void VehicleRentalSystem::handleFileOperations() {
    int choice;
    do {
        displayFileMenu();
        cout << "请输入操作编号: ";
        cin >> choice;
        cin.ignore();
        if (choice == 1) {
            cout << "请输入文件名: ";
            string filename;
            getline(cin, filename);
            manager.saveToFile(filename);
            pauseScreen();
        } else if (choice == 2) {
            cout << "请输入文件名: ";
            string filename;
            getline(cin, filename);
            manager.loadFromFile(filename);
            pauseScreen();
        }
    } while (choice != 3);
}

void VehicleRentalSystem::displayFileMenu() {
    cout << "=== 文件操作 ===" << endl;
    cout << "1. 保存到文件" << endl;
    cout << "2. 从文件读取" << endl;
    cout << "3. 返回主菜单" << endl;
}

void VehicleRentalSystem::clearScreen() {
#ifdef _WIN32
    system("cls");
#else
    system("clear");
#endif
}

void VehicleRentalSystem::pauseScreen() {
    cout << "按回车键继续...";
    cin.get();
}

// ===================== 程序入口 =====================
int main() {
    VehicleRentalSystem system;
    system.run();
    return 0;
}

