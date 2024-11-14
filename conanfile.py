from conan import ConanFile
from conan.tools.cmake import CMakeDeps, CMakeToolchain

class PALRecipe(ConanFile):
    settings = "os", "build_type"

    def requirements(self):
        self.requires("pybind11/2.13.5")
        self.requires("catch2/2.13.10")
        self.requires("nlohmann_json/3.4.0")
        self.requires("optional-lite/3.4.0")
        self.requires("spectra/1.0.1")
        self.requires("onetbb/2021.10.0")
        self.requires("boost/1.83.0")
        # self.requires("cereal/1.3.0")
        self.requires("eigen/3.4.0")
        self.requires("libpng/1.6.43")
        # self.requires("libjpeg-turbo/3.0.2")
        # self.requires("libcurl/8.9.1")
        # self.requires("openssl/3.3.1")
        # self.requires("openvdb/11.0.0")
        # self.requires("stb/cci.20230920")
        # self.requires("rapidjson/cci.20230929")
        # self.requires("clipper2/1.4.0")
        # self.requires("expat/2.6.2")
        # self.requires("cgal/5.6.1")
        self.requires("glew/2.2.0")
        # self.requires("glfw/3.4")
        # self.requires("assimp/5.4.2")

    def generate(self):
        tc = CMakeToolchain(self)
        tc.user_presets_path = False
        tc.generate()
        cd = CMakeDeps(self)
        cd.generate()