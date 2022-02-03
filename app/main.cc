#include <mlixir/mlixir.h>
#include <spdlog/spdlog.h>
#include <iostream>
#include <boost/program_options.hpp>
extern "C" {
#include <libavformat/avformat.h>
}

namespace opt = boost::program_options;

int main(int argc, char *argv[]) {
  std::cout << mlixir::MLIXIR_VERSION << std::endl;

  spdlog::info("Welcome to spdlog!");

  std::string apple_value, orange_value;
  try
  {
    opt::options_description desc("all options");
    desc.add_options()
        ("help,h", "produce help message")
            ("apples,a", opt::value<std::string>(&apple_value)->default_value("10"), "how many apples do you have")
                ("oranges,o", opt::value<std::string>(&orange_value)->default_value("20"), "how many oranges do you have");

    opt::variables_map vm;
    opt::store(opt::parse_command_line(argc, argv, desc), vm);
    opt::notify(vm);

    if (vm.size() == 1 || vm.count("help")) {
      std::cout << desc << std::endl;
      return EXIT_SUCCESS;
    }
  } catch (std::exception& e) {
    spdlog::error(e.what());
    return EXIT_FAILURE;
  }

  std::string apple = fmt::format("options->apples value: {}", apple_value);
  spdlog::info(apple);
  spdlog::info("options->oranges value: {}.", orange_value);

  spdlog::info("Start App!");

  AVFormatContext *avctx;
  std::string url = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8";
  int mr = avformat_open_input(&avctx, url.c_str(), NULL, NULL);
  std::cout << mr << std::endl;

  return 0;
}